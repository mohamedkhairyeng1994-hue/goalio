import 'package:flutter/widgets.dart';

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double blockWidth = 0;
  static double blockHeight = 0;

  static void initFromSize(Size size) {
    _mediaQueryData = MediaQueryData(size: size);
    screenWidth = size.width;
    screenHeight = size.height;
    blockWidth = screenWidth / 100;
    blockHeight = screenHeight / 100;
  }

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth =
        _mediaQueryData!.size.width > 0 ? _mediaQueryData!.size.width : 375.0;
    screenHeight =
        _mediaQueryData!.size.height > 0 ? _mediaQueryData!.size.height : 812.0;
    blockWidth = screenWidth / 100;
    blockHeight = screenHeight / 100;
  }
}

extension ResponsiveSize on num {
  /// Calculates the height based on the screen height.
  /// Standard design height is 812.0 (iPhone X)
  double get h {
    final height =
        SizeConfig.screenHeight > 0 ? SizeConfig.screenHeight : 812.0;
    return (this / 812.0) * height;
  }

  /// Calculates the width based on the screen width.
  /// Standard design width is 375.0 (iPhone X)
  double get w {
    final width = SizeConfig.screenWidth > 0 ? SizeConfig.screenWidth : 375.0;
    return (this / 375.0) * width;
  }

  /// Calculates the font size based on the screen width.
  double get sp {
    final width = SizeConfig.screenWidth > 0 ? SizeConfig.screenWidth : 375.0;
    return (this / 375.0) * width;
  }
}
