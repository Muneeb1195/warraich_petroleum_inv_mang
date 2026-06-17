import 'package:flutter/widgets.dart';

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

const double kMaxContentWidth = 1000;

Widget buildWideLayout(BuildContext context, Widget child) {
  if (!isWide(context)) return child;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
      child: child,
    ),
  );
}
