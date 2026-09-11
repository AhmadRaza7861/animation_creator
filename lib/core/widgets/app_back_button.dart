import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

/// A standardized, modern rounded back button for the entire application.
///
/// Features a tactile rounded container with a soft background, subtle ripple,
/// and an optically centered iOS-style rounded chevron icon.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.iconSize = 16,
    this.borderRadius = 12,
    this.margin = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: size,
      height: size,
      child: Material(
        color: backgroundColor ?? const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: iconColor ?? ColorConstants.darkText,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
