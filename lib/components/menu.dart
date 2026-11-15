part of "components.dart";

void showMenuX(BuildContext context, Offset location, List<MenuEntry> entries) {
  Navigator.of(context, rootNavigator: true).push(_MenuRoute(entries, location));
}

class _MenuRoute<T> extends PopupRoute<T> {
  final List<MenuEntry> entries;

  final Offset location;

  _MenuRoute(this.entries, this.location);

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "menu";

  double get entryHeight => App.isMobile ? 42 : 36;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    var width = entries.first.icon == null ? 216.0 : 242.0;
    final size = MediaQuery.of(context).size;
    var left = location.dx;
    if (left < 10) {
      left = 10;
    }
    if (left + width > size.width - 10) {
      left = size.width - width - 10;
    }
    var top = location.dy;
    var height = 16 + entryHeight * entries.length;
    if (top + height > size.height - 15) {
      top = size.height - height - 15;
    }
    final isDark = context.isDarkMode;
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: kBRS,
              border: Border.all(color: kGlassBorderColor(isDark)),
              boxShadow: kOverlayShadows(context.brightness),
            ),
            child: BlurEffect(
              borderRadius: kBRS,
              child: Material(
                color: context.colorScheme.surface.toOpacity(0.92),
                borderRadius: kBRS,
                child: Container(
                  width: width,
                  padding:
                      const EdgeInsets.symmetric(vertical: kSpaceS, horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        entries.map((e) => buildEntry(e, context)).toList(),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildEntry(MenuEntry entry, BuildContext context) {
    return InkWell(
      borderRadius: kBRXs,
      onTap: () {
        Navigator.of(context).pop();
        entry.onClick();
      },
      child: SizedBox(
        height: entryHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpaceM),
          child: Row(
            children: [
              if (entry.icon != null)
                Icon(
                  entry.icon,
                  size: 18,
                  color: entry.color
                ),
              const SizedBox(width: kSpaceM),
              Text(
                  entry.text,
                  style: TextStyle(color: entry.color)
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Duration get transitionDuration => kDurationFast;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: kCurve);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}

class MenuEntry {
  final String text;
  final IconData? icon;
  final Color? color;
  final void Function() onClick;

  MenuEntry({required this.text, this.icon, this.color, required this.onClick});
}
