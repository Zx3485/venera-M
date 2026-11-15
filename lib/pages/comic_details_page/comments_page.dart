part of 'comic_page.dart';

bool _shouldBlockComment(Comment comment) {
  var blockedWords = appdata.settings["blockedCommentWords"] as List;
  if (blockedWords.isEmpty) return false;
  
  var content = comment.content.toLowerCase();
  for (var word in blockedWords) {
    if (content.contains(word.toString().toLowerCase())) {
      return true;
    }
  }
  return false;
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({
    super.key,
    required this.data,
    required this.source,
    this.replyComment,
  });

  final ComicDetails data;

  final ComicSource source;

  final Comment? replyComment;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  bool _loading = true;
  List<Comment>? _comments;
  String? _error;
  int _page = 1;
  int? maxPage;
  var controller = TextEditingController();
  bool sending = false;

  void firstLoad() async {
    var res = await widget.source.commentsLoader!(
        widget.data.comicId, widget.data.subId, 1, widget.replyComment?.id);
    if (res.error) {
      setState(() {
        _error = res.errorMessage;
        _loading = false;
      });
    } else if (mounted) {
      var filteredComments = res.data.where((c) => !_shouldBlockComment(c)).toList();
      setState(() {
        _comments = filteredComments;
        _loading = false;
        maxPage = res.subData;
      });
    }
  }

  void loadMore() async {
    var res = await widget.source.commentsLoader!(
      widget.data.comicId,
      widget.data.subId,
      _page + 1,
      widget.replyComment?.id,
    );
    if (res.error) {
      context.showMessage(message: res.errorMessage ?? "Unknown Error");
    } else {
      var filteredComments = res.data.where((c) => !_shouldBlockComment(c)).toList();
      setState(() {
        _comments!.addAll(filteredComments);
        _page++;
        if (maxPage == null && res.data.isEmpty) {
          maxPage = _page;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: Appbar(
        title: Text("Comments".tl),
        style: AppbarStyle.shadow,
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (_loading) {
      firstLoad();
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_error != null) {
      return NetworkError(
        message: _error!,
        retry: () {
          setState(() {
            _loading = true;
          });
        },
        withAppbar: false,
      );
    } else {
      var showAvatar =
          _comments!.any((e) {
            return e.avatar != null;
          }) ||
          (widget.replyComment?.avatar != null);
      return Column(
        children: [
          Expanded(
            child: SmoothScrollProvider(
              builder: (context, controller, physics) {
                return ListView.builder(
                  controller: controller,
                  physics: physics,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: _comments!.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      if (widget.replyComment != null) {
                        return Column(
                          children: [
                            _CommentTile(
                              comment: widget.replyComment!,
                              source: widget.source,
                              comic: widget.data,
                              showAvatar: showAvatar,
                              showActions: false,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.fromLTRB(
                                kPageInset,
                                18,
                                kPageInset,
                                6,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: context.colorScheme.onSurface,
                                    width: kRuleThick,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Replies".tl.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.4,
                                  fontWeight: FontWeight.w700,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    }
                    index--;

                    if (index == _comments!.length) {
                      if (_page < (maxPage ?? _page + 1)) {
                        loadMore();
                        return const ListLoadingIndicator();
                      } else {
                        return const SizedBox();
                      }
                    }

                    return _CommentTile(
                      comment: _comments![index],
                      source: widget.source,
                      comic: widget.data,
                      showAvatar: showAvatar,
                    );
                  },
                );
              },
            ),
          ),
          buildBottom(context)
        ],
      );
    }
  }

  Widget buildBottom(BuildContext context) {
    if (widget.source.sendCommentFunc == null) {
      return const SizedBox(
        height: 0,
      );
    }
    return EditorialInputBar(
      controller: controller,
      hint: "Comment".tl,
      sending: sending,
      onSend: () async {
        if (controller.text.isEmpty) {
          return;
        }
        setState(() {
          sending = true;
        });
        var b = await widget.source.sendCommentFunc!(
            widget.data.comicId,
            widget.data.subId,
            controller.text,
            widget.replyComment?.id);
        if (!b.error) {
          controller.text = "";
          setState(() {
            sending = false;
            _loading = true;
            _comments?.clear();
            _page = 1;
            maxPage = null;
          });
        } else {
          context.showMessage(message: b.errorMessage ?? "Error");
          setState(() {
            sending = false;
          });
        }
      },
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.source,
    required this.comic,
    required this.showAvatar,
    this.showActions = true,
  });

  final Comment comment;

  final ComicSource source;

  final ComicDetails comic;

  final bool showAvatar;

  final bool showActions;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  @override
  void initState() {
    likes = widget.comment.score ?? 0;
    isLiked = widget.comment.isLiked ?? false;
    voteStatus = widget.comment.voteStatus;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: kPageInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showAvatar)
            EditorialAvatar(
              size: 34,
              child: widget.comment.avatar == null
                  ? null
                  : AnimatedImage(
                      image: CachedImageProvider(
                        widget.comment.avatar!,
                        sourceKey: widget.source.key,
                      ),
                    ),
            ).paddingRight(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.comment.userName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                if (widget.comment.time != null)
                  Text(
                    widget.comment.time!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                _CommentContent(text: widget.comment.content),
                buildActions(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildActions() {
    if (!widget.showActions) {
      return const SizedBox();
    }
    if (widget.comment.score == null && widget.comment.replyCount == null) {
      return const SizedBox();
    }
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.comment.score != null &&
              widget.source.voteCommentFunc != null)
            buildVote(),
          if (widget.comment.score != null &&
              widget.source.likeCommentFunc != null)
            buildLike(),
          if (widget.comment.replyCount != null) buildReply(),
        ],
      ),
    ).paddingTop(8);
  }

  Widget buildReply() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: EditorialActionChip(
        onTap: () {
          showSideBar(
            context,
            CommentsPage(
              data: widget.comic,
              source: widget.source,
              replyComment: widget.comment,
            ),
            showBarrier: false,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_comment_outlined,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              widget.comment.replyCount.toString(),
              style: TextStyle(
                fontSize: 11.5,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isLiking = false;

  bool isLiked = false;

  var likes = 0;

  Widget buildLike() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: EditorialActionChip(
        active: isLiked,
        onTap: () async {
          if (isLiking) return;
          setState(() {
            isLiking = true;
          });
          var res = await widget.source.likeCommentFunc!(
            widget.comic.comicId,
            widget.comic.subId,
            widget.comment.id!,
            !isLiked,
          );
          if (res.success) {
            isLiked = !isLiked;
            likes += isLiked ? 1 : -1;
          } else {
            context.showMessage(message: res.errorMessage ?? "Error");
          }
          setState(() {
            isLiking = false;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLiking)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isLiked)
              Icon(
                Icons.favorite,
                size: 14,
                color: context.useTextColor(kSoftRed),
              )
            else
              Icon(
                Icons.favorite_border,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
            const SizedBox(width: 6),
            Text(
              likes.toString(),
              style: TextStyle(
                fontSize: 11.5,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? voteStatus;

  bool isVotingUp = false;

  bool isVotingDown = false;

  void vote(bool isUp) async {
    if (isVotingUp || isVotingDown) return;
    setState(() {
      if (isUp) {
        isVotingUp = true;
      } else {
        isVotingDown = true;
      }
    });
    var isCancel = (isUp && voteStatus == 1) || (!isUp && voteStatus == -1);
    var res = await widget.source.voteCommentFunc!(
      widget.comic.comicId,
      widget.comic.subId,
      widget.comment.id!,
      isUp,
      isCancel,
    );
    if (res.success) {
      if (isCancel) {
        voteStatus = 0;
      } else {
        if (isUp) {
          voteStatus = 1;
        } else {
          voteStatus = -1;
        }
      }
      widget.comment.voteStatus = voteStatus;
      widget.comment.score = res.data ?? widget.comment.score;
    } else {
      context.showMessage(message: res.errorMessage ?? "Error");
    }
    setState(() {
      isVotingUp = false;
      isVotingDown = false;
    });
  }

  Widget buildVote() {
    var upColor = context.colorScheme.outline;
    if (voteStatus == 1) {
      upColor = context.useTextColor(kSoftRed);
    }
    var downColor = context.colorScheme.outline;
    if (voteStatus == -1) {
      downColor = context.useTextColor(kSoftBlue);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: EditorialActionChip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.icon(
              isLoading: isVotingUp,
              icon: const Icon(Icons.arrow_upward),
              size: 16,
              color: upColor,
              onPressed: () => vote(true),
            ),
            const SizedBox(width: 2),
            Text(
              widget.comment.score.toString(),
              style: TextStyle(
                fontSize: 11.5,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            Button.icon(
              isLoading: isVotingDown,
              icon: const Icon(Icons.arrow_downward),
              size: 16,
              color: downColor,
              onPressed: () => vote(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentContent extends StatelessWidget {
  const _CommentContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (!text.contains('<') && !text.contains('http')) {
      return SelectableText(text);
    } else {
      return RichCommentContent(text: text);
    }
  }
}
