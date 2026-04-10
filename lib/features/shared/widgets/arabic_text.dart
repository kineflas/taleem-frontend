import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Widget for RTL Arabic text with Amiri font and proper min size.
class ArabicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.textAlign = TextAlign.right,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    );
  }
}

/// Arabic text for Quran (uses Scheherazade with larger size for harakat visibility)
class QuranText extends StatelessWidget {
  final String text;
  final double fontSize;

  const QuranText(this.text, {super.key, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: fontSize,
          height: 1.8,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
