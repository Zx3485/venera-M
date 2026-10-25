import 'dart:typed_data';
import 'package:venera/network/app_dio.dart';

class NetworkCache {
  final Uri uri;

  final Map<String, dynamic> requestHeaders;

  final Map<String, List<String>> responseHeaders;

  final Object? data;

  final DateTime time;

  final int size;

  const NetworkCache({
    required this.uri,
    required this.requestHeaders,
    required this.responseHeaders,
    required this.data,
    required this.time,
    required this.size,
  });
}

class NetworkCacheManager implements Interceptor {
  NetworkCacheManager._();

  static final NetworkCacheManager instance = NetworkCacheManager._();

  factory NetworkCacheManager() => instance;

  final Map<Uri, NetworkCache> _cache = {};

  int size = 0;

  NetworkCache? getCache(Uri uri) {
    return _cache[uri];
  }

  static const _maxCacheSize = 10 * 1024 * 1024;

  void setCache(NetworkCache cache) {
    if (_cache.containsKey(cache.uri)) {
      size -= _cache[cache.uri]!.size;
    }
    while (size > _maxCacheSize) {
      size -= _cache.values.first.size;
      _cache.remove(_cache.keys.first);
    }
    _cache[cache.uri] = cache;
    size += cache.size;
  }

  void removeCache(Uri uri) {
    var cache = _cache[uri];
    if (cache != null) {
      size -= cache.size;
    }
    _cache.remove(uri);
  }

  void clear() {
    _cache.clear();
    size = 0;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.method != "GET") {
      return handler.next(err);
    }
    return handler.next(err);
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.method != "GET") {
      return handler.next(options);
    }
    var cache = getCache(options.uri);
    if (cache == null ||
        !compareHeaders(options.headers, cache.requestHeaders)) {
      if (options.headers['cache-time'] != null) {
        options.headers.remove('cache-time');
      }
      return handler.next(options);
    } else {
      if (options.headers['cache-time'] == 'no') {
        options.headers.remove('cache-time');
        removeCache(options.uri);
        return handler.next(options);
      }
    }
    var time = DateTime.now();
    var diff = time.difference(cache.time);
    if (options.headers['cache-time'] == 'long' &&
        diff < const Duration(hours: 6)) {
      return handler.resolve(Response(
        requestOptions: options,
        data: cache.data,
        headers: Headers.fromMap(cache.responseHeaders)
          ..set('venera-cache', 'true'),
        statusCode: 200,
      ));
    } else if (diff < const Duration(seconds: 5)) {
      return handler.resolve(Response(
        requestOptions: options,
        data: cache.data,
        headers: Headers.fromMap(cache.responseHeaders)
          ..set('venera-cache', 'true'),
        statusCode: 200,
      ));
    } else if (diff < const Duration(hours: 2)) {
      var o = options.copyWith(
        method: "HEAD",
      );
      var dio = AppDio();
      var response = await dio.fetch(o);
      if (response.statusCode == 200 &&
          compareHeaders(cache.responseHeaders, response.headers.map)) {
        return handler.resolve(Response(
          requestOptions: options,
          data: cache.data,
          headers: Headers.fromMap(cache.responseHeaders)
            ..set('venera-cache', 'true'),
          statusCode: 200,
        ));
      }
    }
    removeCache(options.uri);
    handler.next(options);
  }

  static bool compareHeaders(Map<String, dynamic> a, Map<String, dynamic> b) {
    a = Map.from(a);
    b = Map.from(b);
    const shouldIgnore = [
      'cache-time',
      'prevent-parallel',
      'date',
      'x-varnish',
      'cf-ray',
      'connection',
      'vary',
      'content-encoding',
      'report-to',
      'server-timing',
      'token',
      'set-cookie',
      'cf-cache-status',
      'cf-request-id',
      'cf-ray',
      'authorization',
    ];
    for (var key in shouldIgnore) {
      a.remove(key);
      b.remove(key);
    }
    if (a.length != b.length) {
      return false;
    }
    for (var key in a.keys) {
      if (a[key] is List && b[key] is List) {
        if (a[key].length != b[key].length) {
          return false;
        }
        for (var i = 0; i < a[key].length; i++) {
          if (a[key][i] != b[key][i]) {
            return false;
          }
        }
      } else if (a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method != "GET") {
      return handler.next(response);
    }
    // 只缓存 200。
    //
    // 原来这里写的是 `statusCode >= 400` 才跳过，问题是**非标准状态码会漏网**：
    // 拷贝漫画在封禁时返回 HTTP 210 且 body 是
    //   {"code":210,"message":"請到官網更新最新APP..."}
    // 210 < 400，于是这条错误响应被写进了内存缓存；之后同一 URL 的请求
    // 全部命中缓存、永远拿回 210，只有杀进程清空缓存才能恢复
    // —— 这正是"重启就好"的原因。
    //
    // 改成严格只缓存 200 之后，201/204/206/3xx/4xx/5xx 以及 210 这类
    // 非标准码都不会进缓存，错误就不会被固化成"永远的错误"。
    if (response.statusCode != 200) {
      return handler.next(response);
    }
    // 第二层保险：有些站把业务错误塞进 200 响应里，
    //   {"code":210,"message":"..."}
    // 这种也不能缓存，否则错误会被固化。判断依据是顶层 code 字段非 0。
    if (_isBusinessError(response.data)) {
      return handler.next(response);
    }
    var size = _calculateSize(response.data);
    if (size != null && size < 1024 * 1024 && size > 0) {
      var cache = NetworkCache(
        uri: response.requestOptions.uri,
        requestHeaders: response.requestOptions.headers,
        responseHeaders: Map.from(response.headers.map),
        data: response.data,
        time: DateTime.now(),
        size: size,
      );
      setCache(cache);
    }
    handler.next(response);
  }

  /// 判断响应体是否是「HTTP 200 但业务失败」的形态。
  /// 只看顶层 code 字段：存在且不为 0 / "0" 就认为失败。
  static bool _isBusinessError(Object? data) {
    try {
      Map? map;
      if (data is Map) {
        map = data;
      } else if (data is String && data.trimLeft().startsWith('{')) {
        // 大部分源拿到的 text，这里做轻量判断，避免引入 json 解析开销时误伤
        final m = RegExp(r'"code"\s*:\s*(-?\d+)').firstMatch(data);
        if (m != null) {
          final code = int.tryParse(m.group(1) ?? '');
          return code != null && code != 0;
        }
        return false;
      }
      if (map == null) return false;
      final code = map['code'];
      if (code is int) return code != 0;
      if (code is String) return code != '0';
      return false;
    } catch (_) {
      return false;
    }
  }

  static int? _calculateSize(Object? data) {
    if (data == null) {
      return 0;
    }
    if (data is List<int>) {
      return data.length;
    }
    if (data is Uint8List) {
      return data.length;
    }
    if (data is String) {
      if (data.trim().isEmpty) {
        return 0;
      }
      if (data.length < 512 && data.contains("IP address")) {
        return 0;
      }
      return data.length * 4;
    }
    if (data is Map) {
      return data.toString().length * 4;
    }
    return null;
  }
}
