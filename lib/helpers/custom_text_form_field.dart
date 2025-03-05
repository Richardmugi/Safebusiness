import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/color_resources.dart';
import '../utils/dimensions.dart';
import '../widgets/sized_box.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final Color? hintColor;
  final int maxLine;
  final int? minLine;
  final bool multiline;
  final bool hasInputBorder;
  final bool hasBorderSide;
  final bool hasUnderlineBorder;
  final bool isBoldLabel;
  final bool hasSuffixIcon;
  final bool hasPrefixIcon;
  final bool obscureText;
  final bool isBorderEnabled;
  final Color fillColor;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final FocusScope? focusScope;
  final Function? onChanged;
  final TextInputType? inputType;
  final TextInputAction? inputAction;
  final bool? isShowSuffixIcon;
  final IconData? suffixIconUrl;
  final IconData? prefixIconUrl;
  final bool? isPin;
  final bool? isIcon;
  final Function()? onSuffixTap;
  final String? Function(String? text)? validator;
  final bool? isValidator;
  final bool hasMinLine;
  final bool isEnabled;
  final double borderRadius;
  final double textFieldSize;
  final bool hasLable;

  const CustomTextFormField({
    super.key,
    this.focusScope,
    this.hintText = 'type hint here',
    this.nextFocus,
    this.maxLine = 1,
    this.multiline = false,
    this.label = 'This is your label',
    required this.controller,
    this.fillColor = white,
    this.focusNode,
    this.hasBorderSide = false,
    this.hasInputBorder = false,
    this.hasSuffixIcon = false,
    this.hasPrefixIcon = false,
    this.hasUnderlineBorder = false,
    this.hintColor = textForm,
    this.isBoldLabel = true,
    this.isBorderEnabled = true,
    this.obscureText = false,
    this.onChanged,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.isShowSuffixIcon = false,
    this.suffixIconUrl,
    this.prefixIconUrl,
    this.isIcon = false,
    this.onSuffixTap,
    this.isPin = false,
    this.isValidator = false,
    this.validator,
    this.isEnabled = true,
    this.minLine = 1,
    this.hasMinLine = false,
    this.borderRadius = 10,
    this.textFieldSize = 60,
    this.hasLable = true,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.hasLable
            ? Text(
                widget.label!,
                style: TextStyle(
                  color: black,
                  fontWeight: widget.isBoldLabel ? FontWeight.bold : null,
                ),
              )
            : const SizedBox.shrink(),
        widget.hasLable ? verticalSpacing(5) : const SizedBox.shrink(),
        SizedBox(
          height: widget.textFieldSize,
          child: TextFormField(
            enabled: widget.isEnabled,
            controller: widget.controller,
            validator: widget.isValidator! ? widget.validator : null,
            obscureText: widget.isPin! ? _obscureText : false,
            keyboardType:
                widget.multiline ? TextInputType.multiline : TextInputType.text,
            maxLines: widget.maxLine,
            minLines: widget.hasMinLine ? widget.minLine : null,
            inputFormatters: widget.inputType == TextInputType.phone
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp('[0-9+]'))
                  ]
                : null,
            decoration: widget.hasInputBorder
                ? InputDecoration(
                    enabledBorder: widget.isBorderEnabled
                        ? OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius),
                            borderSide: widget.hasBorderSide
                                ? BorderSide(color: borderSideColor)
                                : BorderSide.none,
                          )
                        : null,
                    prefixIcon: widget.hasPrefixIcon
                        ? Icon(widget.prefixIconUrl)
                        : null,
                    suffixIcon: widget.hasSuffixIcon
                        ? widget.isPin!
                            ? IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 30,
                                ),
                                onPressed: _toggle,
                              )
                            : widget.isIcon!
                                ? IconButton(
                                    onPressed: widget.onSuffixTap,
                                    icon: Icon(
                                      widget.suffixIconUrl,
                                      color: textForm,
                                    ),
                                  )
                                : null
                        : const SizedBox(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: widget.hasBorderSide
                          ? BorderSide(color: borderSideColor)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: widget.hasBorderSide
                          ? BorderSide(color: mainColor.withOpacity(0.2))
                          : BorderSide.none,
                    ),
                    hintStyle: GoogleFonts.poppins(
                      color: widget.hintColor,
                      fontSize: Dimensions.FONT_SIZE_DEFAULT,
                    ),
                    filled: true,
                    fillColor: widget.fillColor,
                    hintText: widget.hintText,
                  )
                : null,
            onFieldSubmitted: (_) {
              widget.focusNode!.unfocus();
              FocusScope.of(context).requestFocus(widget.nextFocus);
            },
          ),
        ),
      ],
    );
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
