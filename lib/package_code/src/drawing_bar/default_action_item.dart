import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../drawing_controller.dart';

class DefaultActionItem extends StatelessWidget {
  const DefaultActionItem({
    super.key,
    required this.childBuilder,
    this.onTap,
    this.backgroundColor,
  });

  factory DefaultActionItem.slider({SliderThemeData? theme, double? min, double? max}) {
    return DefaultActionItem(
      childBuilder: (BuildContext context, DrawingController controller) {
        final drawConfig = controller.drawConfig.value;
        final bool isEraser = drawConfig.contentType.toString() == 'Eraser';
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                child: child,
              ),
            );
          },
          child: isEraser
              ? SizedBox(
                  key: const ValueKey('eraserslider'),
                  height: 24,
                  child: SliderTheme(
                    data: theme ?? SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.grey,
                      thumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: Slider(
                      value: drawConfig.strokeWidth,
                      max: 100, // Eraser maximum size is arbitrarily larger
                      min: min ?? 1,
                      onChanged: (double value) {
                        controller.setStyle(strokeWidth: value);
                      },
                    ),
                  ),
                )
              : SizedBox(
                  key: const ValueKey('brushslider'),
                  height: 24,
                  child: SliderTheme(
                    data: theme ?? SliderTheme.of(context),
                    child: Slider(
                      value: drawConfig.strokeWidth,
                      max: max ?? 50,
                      min: min ?? 1,
                      onChanged: (double value) {
                        controller.setStyle(strokeWidth: value);
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }

  factory DefaultActionItem.undo() {
    return DefaultActionItem(
      onTap: (DrawingController controller) => controller.undo(),
      childBuilder: (BuildContext context, DrawingController controller) {
        return Icon(
          CupertinoIcons.arrow_turn_up_left,
          color: controller.canUndo() ? null : Colors.grey,
          size: 24,
        );
      },
    );
  }

  factory DefaultActionItem.redo() {
    return DefaultActionItem(
      onTap: (DrawingController controller) => controller.redo(),
      childBuilder: (BuildContext context, DrawingController controller) {
        return Icon(
          CupertinoIcons.arrow_turn_up_right,
          color: controller.canRedo() ? null : Colors.grey,
          size: 24,
        );
      },
    );
  }

  factory DefaultActionItem.turn() {
    return DefaultActionItem(
      onTap: (DrawingController controller) => controller.turn(),
      childBuilder: (BuildContext context, DrawingController controller) {
        return const Icon(CupertinoIcons.rotate_right, size: 24);
      },
    );
  }

  factory DefaultActionItem.clear() {
    return DefaultActionItem(
      onTap: (DrawingController controller) => controller.clear(),
      childBuilder: (BuildContext context, DrawingController controller) {
        return Icon(
          CupertinoIcons.trash,
          size: 24,
          color: controller.canClear() ? null : Colors.grey,
        );
      },
    );
  }

  final Widget Function(BuildContext context, DrawingController controller) childBuilder;
  final void Function(DrawingController controller)? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final DrawingController? controller = DrawingControllerProvider.maybeOf(context);

    if (controller == null) {
      throw Exception(
        'DefaultActionItem must be placed within a DrawingBar or DrawingControllerProvider',
      );
    }

    return TextButton(
      onPressed: () => onTap?.call(controller),
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white,
        padding: const EdgeInsets.all(5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable?>[controller.drawConfig, controller]),
        builder: (BuildContext context, Widget? child) {
          return childBuilder(context, controller);
        },
      ),
    );
  }
}
