import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  late final Size _size;
  late final double _shortestSide;

  ResponsiveHelper(this.context) {
    _size = MediaQuery.of(context).size;
    _shortestSide = _size.shortestSide;
  }

  double get width => _size.width;
  double get height => _size.height;

  bool get isPhone => _shortestSide < 600;
  bool get isTablet => _shortestSide >= 600 && _shortestSide < 900;
  bool get isDesktop => _shortestSide >= 900;

  bool get isPortrait => MediaQuery.of(context).orientation == Orientation.portrait;

  double font(double base) {
    if (isDesktop) return base * 1.15;
    if (isTablet) return base * 1.08;
    return base;
  }

  int gridColumns({int phoneColumns = 2, int tabletColumns = 3, int desktopColumns = 4}) {
    if (isDesktop) return desktopColumns;
    if (isTablet) return tabletColumns;
    return phoneColumns;
  }

  EdgeInsets get pagePadding {
    if (isDesktop) return const EdgeInsets.symmetric(horizontal: 48, vertical: 20);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    return const EdgeInsets.all(16);
  }

  double get micButtonRadius => isDesktop ? 40 : (isTablet ? 36 : 32);

  double get speakerButtonRadius => isDesktop ? 32 : (isTablet ? 29 : 26);

  double get maxContentWidth => isDesktop ? 720 : double.infinity;

  double space(double base) => isDesktop ? base * 1.25 : base;
}
