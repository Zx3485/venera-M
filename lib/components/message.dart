part of "components.dart";

void showToast({
  required String message,
  required BuildContext context,
  Widget? icon,
  Widget? trailing,
  int? seconds,
}) {
  var state = context.findAncestorStateOfType<OverlayWidgetState>();
  late final OverlayEntry newEntry;
  final key = GlobalKey<_ToastOverlayState>();
  newEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
            key: key,
            message: message,
            icon: icon,
            trailing: trailing,
            onRemove: () => state?.remove(newEntry),
          ));

  state?.addOverlay(newEntry);

  Timer(Duration(seconds: seconds ?? 2), () => key.currentState?.dismiss());
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.onRemove,
    this.icon,
    this.trailing,
    super.key,
  });

  final String message;

  final Widget? icon;

  final Widget? trailing;

  final VoidCallback onRemove;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kDurationNormal,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: kCurve,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  /// 淡出后再真正移除 OverlayEntry，避免瞬间消失的生硬感。
  void dismiss() {
    if (!_controller.isCompleted) {
      widget.onRemove();
      return;
    }
    _controller.reverse().whenCompleteOrCancel(widget.onRemove);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(_fade),
            child: Material(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: kBRS,
              elevation: 0,
              shadowColor: Colors.transparent,
              textStyle:
                  ts.withColor(Theme.of(context).colorScheme.onInverseSurface),
              child: IconTheme(
                data: IconThemeData(
                    color: Theme.of(context).colorScheme.onInverseSurface),
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: kSpaceM, horizontal: kSpaceL),
                    constraints: BoxConstraints(
                      maxWidth: context.width - 32,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) widget.icon!.paddingRight(8),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.trailing != null)
                          widget.trailing!.paddingLeft(8)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget(this.child, {super.key});

  final Widget child;

  @override
  State<OverlayWidget> createState() => OverlayWidgetState();
}

class OverlayWidgetState extends State<OverlayWidget> {
  final overlayKey = GlobalKey<OverlayState>();

  var entries = <OverlayEntry>[];

  void addOverlay(OverlayEntry entry) {
    if (overlayKey.currentState != null) {
      overlayKey.currentState!.insert(entry);
      entries.add(entry);
    }
  }

  void remove(OverlayEntry entry) {
    if (entries.remove(entry)) {
      entry.remove();
    }
  }

  void removeAll() {
    for (var entry in entries) {
      entry.remove();
    }
    entries.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: overlayKey,
      initialEntries: [OverlayEntry(builder: (context) => widget.child)],
    );
  }
}

void showDialogMessage(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: title,
      content: Text(message).paddingHorizontal(16),
      actions: [
        FilledButton(
          onPressed: context.pop,
          child: Text("OK".tl),
        )
      ],
    ),
  );
}

Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  required void Function() onConfirm,
  String confirmText = "Confirm",
  Color? btnColor,
}) {
  return showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: title,
      content: Text(content).paddingHorizontal(16).paddingVertical(8),
      actions: [
        FilledButton(
          onPressed: () {
            context.pop();
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: btnColor,
          ),
          child: Text(confirmText.tl),
        ),
      ],
    ),
  );
}

class LoadingDialogController {
  double? _progress;

  String? _message;

  void Function()? _closeDialog;

  void Function(double? value)? _serProgress;

  void Function(String message)? _setMessage;

  bool closed = false;

  void close() {
    if (closed) {
      return;
    }
    closed = true;
    if (_closeDialog == null) {
      Future.microtask(_closeDialog!);
    } else {
      _closeDialog!();
    }
  }

  void setProgress(double? value) {
    if (closed) {
      return;
    }
    _serProgress?.call(value);
  }

  void setMessage(String message) {
    if (closed) {
      return;
    }
    _setMessage?.call(message);
  }
}

LoadingDialogController showLoadingDialog(
  BuildContext context, {
  void Function()? onCancel,
  bool barrierDismissible = true,
  bool allowCancel = true,
  String? message,
  String cancelButtonText = "Cancel",
  bool withProgress = false,
}) {
  var controller = LoadingDialogController();
  controller._message = message;

  if (withProgress) {
    controller._progress = 0;
  }

  var loadingDialogRoute = DialogRoute(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        controller._serProgress = (value) {
          setState(() {
            controller._progress = value;
          });
        };
        controller._setMessage = (message) {
          setState(() {
            controller._message = message;
          });
        };
        return ContentDialog(
          title: controller._message ?? 'Loading',
          content: LinearProgressIndicator(
            value: controller._progress,
            backgroundColor: context.colorScheme.surfaceContainer,
          ).paddingHorizontal(16).paddingVertical(16),
          actions: [
            FilledButton(
              onPressed: allowCancel
                  ? () {
                      controller.close();
                      onCancel?.call();
                    }
                  : null,
              child: Text(cancelButtonText.tl),
            )
          ],
        );
      });
    },
  );

  var navigator = Navigator.of(context, rootNavigator: true);

  navigator.push(loadingDialogRoute).then((value) => controller.closed = true);

  controller._closeDialog = () {
    navigator.removeRoute(loadingDialogRoute);
  };

  return controller;
}

class ContentDialog extends StatelessWidget {
  const ContentDialog({
    super.key,
    this.title, // 如果不传 title 将不会展示
    required this.content,
    this.dismissible = true,
    this.actions = const [],
  });

  final String? title;

  final Widget content;

  final List<Widget> actions;

  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    var content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title != null
              ? Appbar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: dismissible ? context.pop : null,
            ),
            title: Text(title!),
            backgroundColor: Colors.transparent,
          )
              : const SizedBox.shrink(),
          this.content,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ).paddingRight(12),
          const SizedBox(height: 16),
        ],
      ),
    );
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: kBRL,
        side: context.brightness == Brightness.dark
            ? BorderSide(
                color: context.colorScheme.outlineVariant.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      insetPadding: context.width < 400
          ? const EdgeInsets.symmetric(horizontal: kSpaceXs)
          : const EdgeInsets.symmetric(horizontal: kSpaceL),
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: context.colorScheme.surfaceContainerHigh,
      child: AnimatedSize(
        duration: kDurationNormal,
        curve: kCurve,
        alignment: Alignment.topCenter,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              minWidth: math.min(400, context.width - 16),
            ),
            child: MediaQuery.removePadding(
              removeTop: true,
              removeBottom: true,
              context: context,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showInputDialog({
  required BuildContext context,
  required String title,
  String? hintText,
  required FutureOr<Object?> Function(String) onConfirm,
  String? initialValue,
  String confirmText = "Confirm",
  String cancelText = "Cancel",
  RegExp? inputValidator,
  String? image,
  Uint8List? imageData,
}) {
  var controller = TextEditingController(text: initialValue);
  bool isLoading = false;
  String? error;

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ContentDialog(
            title: title,
            content: Column(
              children: [
                if (image != null)
                  SizedBox(
                    height: 108,
                    child: Image.network(image, fit: BoxFit.none),
                  ).paddingBottom(8),
                if (image == null && imageData != null)
                  SizedBox(
                    height: 108,
                    child: Image.memory(imageData, fit: BoxFit.none),
                  ).paddingBottom(8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                    errorText: error,
                  ),
                ).paddingHorizontal(12),
              ],
            ),
            actions: [
              Button.filled(
                isLoading: isLoading,
                onPressed: () async {
                  if (inputValidator != null &&
                      !inputValidator.hasMatch(controller.text)) {
                    setState(() => error = "Invalid input");
                    return;
                  }
                  var futureOr = onConfirm(controller.text);
                  Object? result;
                  if (futureOr is Future) {
                    setState(() => isLoading = true);
                    result = await futureOr;
                    setState(() => isLoading = false);
                  } else {
                    result = futureOr;
                  }
                  if (result == null) {
                    context.pop();
                  } else {
                    setState(() => error = result.toString());
                  }
                },
                child: Text(confirmText.tl),
              ),
            ],
          );
        },
      );
    },
  );
}

void showInfoDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = "OK",
}) {
  showDialog(
    context: context,
    builder: (context) {
      return ContentDialog(
        title: title,
        content: Text(content).paddingHorizontal(16).paddingVertical(8),
        actions: [
          Button.filled(
            onPressed: context.pop,
            child: Text(confirmText.tl),
          ),
        ],
      );
    },
  );
}

Future<int?> showSelectDialog({
  required String title,
  required List<String> options,
  int? initialIndex,
}) async {
  int? current = initialIndex;

  await showDialog(
    context: App.rootContext,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ContentDialog(
            title: title,
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Select(
                    current: current == null ? "" : options[current!],
                    values: options,
                    minWidth: 156,
                    onTap: (i) {
                      setState(() {
                        current = i;
                      });
                    },
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  current = null;
                  context.pop();
                },
                child: Text('Cancel'.tl),
              ),
              FilledButton(
                onPressed: current == null ? null : context.pop,
                child: Text('Confirm'.tl),
              ),
            ],
          );
        },
      );
    },
  );

  return current;
}
