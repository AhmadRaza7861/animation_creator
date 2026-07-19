import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final double initialOpacity;
  final void Function(Color color, double opacity) onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.initialOpacity,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    // Reconstruct the color with its alpha opacity layer intact
    _currentColor = widget.initialColor.withValues(alpha: widget.initialOpacity);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.palette_rounded, color: Color(0xFFFF9114)),
          SizedBox(width: 8),
          Text(
            'Color Picker',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF3C3043),
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: (Color color) {
            setState(() {
              _currentColor = color;
            });
          },
          enableAlpha: true,
          labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
          pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // Extract rgb color and opacity separately to apply only when Done is clicked
            final rgbColor = Color.fromARGB(255, _currentColor.red, _currentColor.green, _currentColor.blue);
            widget.onColorChanged(rgbColor, _currentColor.opacity);
            Navigator.pop(context);
          },
          child: const Text(
            'Done',
            style: TextStyle(
              color: Color(0xFFFF9114),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
