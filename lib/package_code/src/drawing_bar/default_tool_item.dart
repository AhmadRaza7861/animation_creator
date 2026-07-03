import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../helpers.dart';
import '../../paint_contents.dart';
import '../drawing_controller.dart';

class DefaultToolItem extends StatelessWidget {
  const DefaultToolItem({
    super.key,
    required this.icon,
    required this.content,
    this.onTap,
    this.color,
    this.activeColor = Colors.blue,
    this.iconSize = 24,
    this.backgroundColor,
    this.label,
  });

  factory DefaultToolItem.pen() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(FreehandLine()),
      icon: Icons.edit,
      content: FreehandLine,
      label: 'Pen',
    );
  }

  factory DefaultToolItem.brush() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(SmoothLine()),
      icon: Icons.brush,
      content: SmoothLine,
      label: 'Brush',
    );
  }

  factory DefaultToolItem.eraser() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(Eraser()),
      icon: Icons.cleaning_services,
      content: Eraser,
      label: 'Eraser',
    );
  }

  factory DefaultToolItem.rectangle() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(Rectangle()),
      icon: Icons.rectangle_outlined,
      content: Rectangle,
      label: 'Rect',
    );
  }

  factory DefaultToolItem.circle() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(Circle()),
      icon: Icons.circle_outlined,
      content: Circle,
      label: 'Circle',
    );
  }

  factory DefaultToolItem.straightLine() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(SimpleLine()),
      icon: Icons.show_chart,
      content: SimpleLine,
      label: 'Simple Line',
    );
  }

  factory DefaultToolItem.text({required BuildContext context}) {
    return DefaultToolItem(
      onTap: (DrawingController controller) async {
        String text = '';
        final bool? success = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Enter Text'),
              content: TextField(
                onChanged: (v) => text = v,
                decoration: const InputDecoration(hintText: 'Enter text here'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );

        if (success == true && text.isNotEmpty) {
          controller.setPaintContent(TextContent(text: text));
        }
      },
      icon: Icons.text_fields,
      content: TextContent,
      label: 'Text',
    );
  }

  factory DefaultToolItem.lasso() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(Lasso()),
      icon: Icons.gesture,
      content: Lasso,
      label: 'Lasso',
    );
  }

  factory DefaultToolItem.eyedropper() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(Eyedropper()),
      icon: Icons.colorize,
      content: Eyedropper,
      label: 'Picker',
    );
  }

  factory DefaultToolItem.blur() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(BlurContent()),
      icon: CupertinoIcons.drop,
      content: BlurContent,
      label: 'Blur',
    );
  }

  factory DefaultToolItem.smudge() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(SmudgeContent()),
      icon: Icons.fingerprint,
      content: SmudgeContent,
      label: 'Smudge',
    );
  }

  factory DefaultToolItem.fill() {
    return DefaultToolItem(
      onTap: (DrawingController controller) =>
          controller.setPaintContent(FillContent()),
      icon: Icons.format_color_fill,
      content: FillContent,
      label: 'Fill',
    );
  }

  final void Function(DrawingController controller)? onTap;

  final Type content;
  final IconData icon;
  final double iconSize;
  final Color? color;
  final Color activeColor;
  final Color? backgroundColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final DrawingController? controller = DrawingControllerProvider.maybeOf(
      context,
    );

    if (controller == null) {
      throw Exception(
        'DefaultToolItem must be placed within a DrawingBar or DrawingControllerProvider',
      );
    }

    return TextButton(
      onPressed: () => onTap?.call(controller),
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      child: ExValueBuilder<DrawConfig>(
        valueListenable: controller.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.contentType != n.contentType &&
            (p.contentType == content || n.contentType == content),
        builder: (BuildContext context, DrawConfig value, Widget? child) {
          final bool isActive = value.contentType == content;
          final Color currentColor = isActive
              ? activeColor
              : (color ?? Colors.grey);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: currentColor),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(fontSize: 10, color: currentColor),
                ),
            ],
          );
        },
      ),
    );
  }
}
