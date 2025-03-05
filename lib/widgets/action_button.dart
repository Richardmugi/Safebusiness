// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:safebusiness/utils/dimensions.dart';

class ActionButton extends StatelessWidget {
  ActionButton({
    super.key,
    required this.onPressed,
    required this.actionText,
  });
  Function onPressed;
  String actionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: MediaQuery.of(context).size.width * 0.9,
      height: 50,
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextButton(
        onPressed: () {
          onPressed();
        },
        child: Text(
          actionText,
          style: const TextStyle(
              fontSize: Dimensions.FONT_SIZE_DEFAULT,
              fontWeight: FontWeight.w500,
              color: white),
        ),
      ),
    );
  }
}
