import 'package:flutter/material.dart';

class AppLayout {
  static const compact = 768.0;
  static const expanded = 1280.0;
  static const ultrawide = 1920.0;
  static const maxContentWidth = 1440.0;
  static const formMaxWidth = 720.0;
  static const dialogMaxWidth = 420.0;

  final double width;

  const AppLayout(this.width);

  factory AppLayout.of(BuildContext context) =>
      AppLayout(MediaQuery.sizeOf(context).width);

  bool get isCompact => width < compact;

  bool get isMedium => width >= compact && width < expanded;

  bool get isExpanded => width >= expanded;

  bool get isUltrawide => width >= ultrawide;

  bool get useBottomNav => isCompact;

  bool get useSideNav => !isCompact;

  bool get sideNavExtended => isExpanded;

  bool get useTable => isExpanded;

  int get cardColumns => isMedium ? 2 : 1;

  int get statsColumns {
    if (isCompact) return 1;
    if (isMedium) return 2;
    return 3;
  }
}
