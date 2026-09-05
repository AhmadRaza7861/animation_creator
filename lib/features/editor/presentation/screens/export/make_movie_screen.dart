import 'package:flutter/material.dart';
import '../../../../../package_code/src/drawing_controller.dart';
import '../../controllers/editor_controller.dart';
import '../../../services/movie_export_service.dart';
import 'export_progress_screen.dart';

class OutputSizePreset {
  final String label;
  final String resolution;
  final Size size;

  const OutputSizePreset({
    required this.label,
    required this.resolution,
    required this.size,
  });
}

class MakeMovieScreen extends StatefulWidget {
  final List<DrawingController> canvases;
  final CanvasBackground globalBackground;
  final String initialMovieName;
  final String initialFormat; // 'Mp4' or 'GIF'
  final int fps;
  final double? projectAspectRatio;

  const MakeMovieScreen({
    super.key,
    required this.canvases,
    required this.globalBackground,
    required this.initialMovieName,
    required this.initialFormat,
    required this.fps,
    this.projectAspectRatio,
  });

  @override
  State<MakeMovieScreen> createState() => _MakeMovieScreenState();
}

class _MakeMovieScreenState extends State<MakeMovieScreen> {
  late TextEditingController _nameController;
  late String _format; // 'MP4' or 'GIF'
  late OutputSizePreset _selectedPreset;
  bool _transparentBackground = false;
  bool _includeWatermark = true;

  static const List<OutputSizePreset> _presets = [
    OutputSizePreset(
      label: '1080p (Full HD)',
      resolution: '1920x1080',
      size: Size(1920, 1080),
    ),
    OutputSizePreset(
      label: '720p (HD)',
      resolution: '1280x720',
      size: Size(1280, 720),
    ),
    OutputSizePreset(
      label: 'TikTok / Shorts (9:16)',
      resolution: '1080x1920',
      size: Size(1080, 1920),
    ),
    OutputSizePreset(
      label: 'Square (1:1)',
      resolution: '1080x1080',
      size: Size(1080, 1080),
    ),
    OutputSizePreset(
      label: 'Instagram Portrait (4:5)',
      resolution: '1080x1350',
      size: Size(1080, 1350),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMovieName.trim().isEmpty ? 'FlipaClip' : widget.initialMovieName,
    );

    // Format is pre-selected according to project creation selection ('Mp4' or 'GIF')
    final String initialUpper = widget.initialFormat.toUpperCase();
    _format = (initialUpper == 'GIF') ? 'GIF' : 'MP4';

    // Pick matching preset for project aspect ratio if available
    _selectedPreset = _matchPresetForAspectRatio(widget.projectAspectRatio);
  }

  OutputSizePreset _matchPresetForAspectRatio(double? ar) {
    if (ar == null) return _presets.first;
    if ((ar - (9.0 / 16.0)).abs() < 0.05) {
      return _presets[2]; // 9:16
    }
    if ((ar - 1.0).abs() < 0.05) {
      return _presets[3]; // 1:1
    }
    if ((ar - (4.0 / 5.0)).abs() < 0.05) {
      return _presets[4]; // 4:5
    }
    return _presets.first; // Default 16:9
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showOutputSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'Select Output Size',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                const Divider(),
                ..._presets.map((preset) {
                  final isSelected = preset == _selectedPreset;
                  return ListTile(
                    title: Text(
                      preset.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFF4B72) : const Color(0xFF212121),
                      ),
                    ),
                    subtitle: Text(preset.resolution),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF4B72))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'Select Format',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('MP4 (Video)', style: TextStyle(fontSize: 16)),
                  subtitle: const Text('Standard high quality video format'),
                  trailing: _format == 'MP4'
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF4B72))
                      : null,
                  onTap: () {
                    setState(() {
                      _format = 'MP4';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('GIF (Animation)', style: TextStyle(fontSize: 16)),
                  subtitle: const Text('Animated image format with repeating loop'),
                  trailing: _format == 'GIF'
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF4B72))
                      : null,
                  onTap: () {
                    setState(() {
                      _format = 'GIF';
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMakeMoviePressed() {
    final String movieName = _nameController.text.trim().isEmpty
        ? 'FlipaClip_Movie'
        : _nameController.text.trim();

    final options = ExportOptions(
      movieName: movieName,
      format: _format,
      outputSize: _selectedPreset.size,
      fps: widget.fps,
      transparentBackground: _transparentBackground,
      includeWatermark: _includeWatermark,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportProgressScreen(
          canvases: widget.canvases,
          globalBackground: widget.globalBackground,
          options: options,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalFrames = widget.canvases.length;
    final int fps = widget.fps > 0 ? widget.fps : 12;
    final double durationSeconds = totalFrames / fps;
    final String formattedDuration = durationSeconds >= 10
        ? '${durationSeconds.toStringAsFixed(0)}s'
        : '${durationSeconds.toStringAsFixed(1)}s';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF212121), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make movie',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movie Name Input
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF4B72), width: 2.0),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF4B72), width: 2.5),
                        ),
                        suffixIcon: _nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _nameController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (text) => setState(() {}),
                    ),

                    const SizedBox(height: 32),

                    // DETAILS Section Header
                    const Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF8E8E93),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Output Size Row
                    _buildSettingTile(
                      title: 'OUTPUT SIZE',
                      subtitle: '${_selectedPreset.label.split(' ').first} (${_selectedPreset.resolution})',
                      onTap: _showOutputSizePicker,
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // Format Row
                    _buildSettingTile(
                      title: 'FORMAT',
                      subtitle: _format,
                      onTap: _showFormatPicker,
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E)),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // Transparent Background Row
                    _buildSettingTile(
                      title: 'TRANSPARENT BACKGROUND',
                      subtitle: null,
                      trailing: Switch(
                        value: _transparentBackground,
                        activeColor: const Color(0xFFFF4B72),
                        activeTrackColor: const Color(0xFFFF4B72).withValues(alpha: 0.4),
                        onChanged: (val) {
                          setState(() {
                            _transparentBackground = val;
                          });
                        },
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // FlipaClip Watermark Row
                    _buildSettingTile(
                      title: 'FLIPACLIP WATERMARK',
                      subtitle: null,
                      trailing: Switch(
                        value: _includeWatermark,
                        activeColor: const Color(0xFFFF4B72),
                        activeTrackColor: const Color(0xFFFF4B72).withValues(alpha: 0.4),
                        onChanged: (val) {
                          setState(() {
                            _includeWatermark = val;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 36),

                    // MAKE MOVIE Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4B72),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _onMakeMoviePressed,
                        child: const Text(
                          'MAKE MOVIE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Information Pill (FPS / TOTAL DURATION / TOTAL FRAMES)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF232326),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(value: '$fps', label: 'FPS'),
                    Container(height: 28, width: 1, color: Colors.white24),
                    _buildInfoColumn(value: formattedDuration, label: 'TOTAL DURATION'),
                    Container(height: 28, width: 1, color: Colors.white24),
                    _buildInfoColumn(value: '$totalFrames', label: 'TOTAL FRAMES'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
