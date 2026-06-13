import 'dart:io';
import 'package:flutter/material.dart';

class Responsive {
  static bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static bool isNarrow(BuildContext context) {
    return MediaQuery.of(context).size.width <= 900;
  }
}
