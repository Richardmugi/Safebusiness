import 'package:flutter/material.dart';

Widget customDivider({
  Color? color,
  double indent = 20,
  double endIndent = 20,
  double thickness = 1,
  double height = 10,
}) {
  return Divider(
    color: color,
    indent: indent,
    endIndent: endIndent,
    thickness: thickness,
    height: height,
  );
}
