import 'package:flutter/widgets.dart';

enum DeviceType { phone, tabletPortrait, tabletLandscape, desktop }

class Responsive {
  static DeviceType typeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return DeviceType.phone;
    if (w < 900) return DeviceType.tabletPortrait;
    if (w < 1280) return DeviceType.tabletLandscape;
    return DeviceType.desktop;
  }

  /// 列表网格的列数。
  static int gridColumns(BuildContext context) {
    switch (typeOf(context)) {
      case DeviceType.phone:
        return 3;
      case DeviceType.tabletPortrait:
        return 4;
      case DeviceType.tabletLandscape:
        return 5;
      case DeviceType.desktop:
        final w = MediaQuery.sizeOf(context).width;
        if (w >= 1920) return 8;
        if (w >= 1600) return 7;
        return 6;
    }
  }

  /// 详情页是否使用宽屏双栏布局（左侧播放器，右侧封面/简介）。
  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 900;
  }

  /// 内容区水平内边距。
  static double horizontalPadding(BuildContext context) {
    switch (typeOf(context)) {
      case DeviceType.phone:
        return 12;
      case DeviceType.tabletPortrait:
        return 20;
      case DeviceType.tabletLandscape:
        return 28;
      case DeviceType.desktop:
        return 40;
    }
  }
}
