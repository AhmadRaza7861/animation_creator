import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final switchTheme = theme.switchTheme;

    final bool isEnabled = onChanged != null;

    // Resolve thumb and track colors using WidgetState resolution
    final Set<WidgetState> states = {
      if (value) WidgetState.selected,
      if (!isEnabled) WidgetState.disabled,
    };

    final Color resolvedThumbColor = switchTheme.thumbColor?.resolve(states) ?? 
        (value ? theme.colorScheme.primary : theme.disabledColor);

    final Color resolvedTrackColor = switchTheme.trackColor?.resolve(states) ?? 
        (value ? theme.colorScheme.primary.withOpacity(0.5) : theme.disabledColor.withOpacity(0.5));

    return GestureDetector(
      onTap: isEnabled ? () => onChanged!(!value) : null,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: resolvedTrackColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resolvedThumbColor,
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 3,
                            offset: const Offset(0, 1.5),
                          )
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
