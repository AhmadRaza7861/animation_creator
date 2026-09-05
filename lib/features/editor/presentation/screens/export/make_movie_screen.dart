import 'package:flutter/material.dart';
import '../../../../../package_code/src/drawing_controller.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../controllers/editor_controller.dart';
import '../../../services/movie_export_service.dart';
import 'export_progress_screen.dart';

class OutputSizePreset {
  final String label;
  final String resolution;
  final Size size;
  final String badge;

  const OutputSizePreset({
    required this.label,
    required this.resolution,
    required this.size,
    required this.badge,
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
      label: 'Full HD 1080p',
      resolution: '1920 x 1080',
      size: Size(1920, 1080),
      badge: '16:9',
    ),
    OutputSizePreset(
      label: 'HD 720p',
      resolution: '1280 x 720',
      size: Size(1280, 720),
      badge: '16:9',
    ),
    OutputSizePreset(
      label: 'Shorts / TikTok',
      resolution: '1080 x 1920',
      size: Size(1080, 1920),
      badge: '9:16',
    ),
    OutputSizePreset(
      label: 'Square Post',
      resolution: '1080 x 1080',
      size: Size(1080, 1080),
      badge: '1:1',
    ),
    OutputSizePreset(
      label: 'Portrait Post',
      resolution: '1080 x 1350',
      size: Size(1080, 1350),
      badge: '4:5',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMovieName.trim().isEmpty ? 'My Animation' : widget.initialMovieName,
    );

    final String initialUpper = widget.initialFormat.toUpperCase();
    _format = (initialUpper == 'GIF') ? 'GIF' : 'MP4';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Output Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.darkText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: ColorConstants.mediumText, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: ColorConstants.border_color),
                ..._presets.map((preset) {
                  final isSelected = preset == _selectedPreset;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorConstants.primaryLight : ColorConstants.cardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        preset.badge,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? ColorConstants.primaryDark : ColorConstants.mediumText,
                        ),
                      ),
                    ),
                    title: Text(
                      preset.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? ColorConstants.primary : ColorConstants.darkText,
                      ),
                    ),
                    subtitle: Text(
                      preset.resolution,
                      style: const TextStyle(fontSize: 12, color: ColorConstants.mediumText),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: ColorConstants.primary)
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

  void _onMakeMoviePressed() {
    final String movieName = _nameController.text.trim().isEmpty
        ? 'Clipax_Animation'
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make Movie',
          style: TextStyle(
            color: ColorConstants.darkText,
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
                    // Movie Name Label
                    const Text(
                      'ANIMATION NAME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: ColorConstants.mediumText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Movie Name Input
                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ColorConstants.border_color),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.darkText,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter animation name...',
                          hintStyle: const TextStyle(color: ColorConstants.subTextColor, fontWeight: FontWeight.normal),
                          suffixIcon: _nameController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: ColorConstants.mediumText),
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
                    ),

                    const SizedBox(height: 20),

                    // FORMAT SEGMENT TOGGLE
                    const Text(
                      'EXPORT FORMAT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: ColorConstants.mediumText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ColorConstants.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ColorConstants.border_color),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFormatTab(
                              label: 'MP4 Video',
                              subLabel: 'High Quality',
                              formatValue: 'MP4',
                              icon: Icons.movie_outlined,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildFormatTab(
                              label: 'GIF Animation',
                              subLabel: 'Looping',
                              formatValue: 'GIF',
                              icon: Icons.gif_box_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DETAILS Section Header
                    const Text(
                      'SETTINGS & OPTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: ColorConstants.mediumText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ColorConstants.border_color),
                      ),
                      child: Column(
                        children: [
                          // Output Size Row
                          _buildSettingTile(
                            icon: Icons.aspect_ratio_rounded,
                            title: 'Output Size',
                            subtitle: '${_selectedPreset.label} (${_selectedPreset.resolution})',
                            onTap: _showOutputSizePicker,
                            trailing: const Icon(Icons.chevron_right_rounded, color: ColorConstants.mediumText),
                          ),

                          const Divider(height: 1, color: ColorConstants.border_color),

                          // Transparent Background Row
                          _buildSettingTile(
                            icon: Icons.opacity_rounded,
                            title: 'Transparent Background',
                            subtitle: _transparentBackground ? 'Enabled (PNG layers)' : 'Off',
                            trailing: Switch(
                              value: _transparentBackground,
                              activeColor: ColorConstants.primary,
                              activeTrackColor: ColorConstants.primaryLight,
                              onChanged: (val) {
                                setState(() {
                                  _transparentBackground = val;
                                });
                              },
                            ),
                          ),

                          const Divider(height: 1, color: ColorConstants.border_color),

                          // Clipax Watermark Row
                          _buildSettingTile(
                            icon: Icons.verified_rounded,
                            title: 'Clipax Watermark',
                            subtitle: _includeWatermark ? 'Included on bottom-left' : 'No watermark',
                            trailing: Switch(
                              value: _includeWatermark,
                              activeColor: ColorConstants.primary,
                              activeTrackColor: ColorConstants.primaryLight,
                              onChanged: (val) {
                                setState(() {
                                  _includeWatermark = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Pinned Bottom Action Section (Always in front & visible without scrolling)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // MAKE MOVIE Primary Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          ColorConstants.primary,
                          ColorConstants.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: _onMakeMoviePressed,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.movie_creation_outlined, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'MAKE MOVIE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Information Pill (FPS / TOTAL DURATION / TOTAL FRAMES)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2533),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(value: '$fps', label: 'FPS'),
                        Container(height: 26, width: 1, color: Colors.white12),
                        _buildInfoColumn(value: formattedDuration, label: 'DURATION'),
                        Container(height: 26, width: 1, color: Colors.white12),
                        _buildInfoColumn(value: '$totalFrames', label: 'TOTAL FRAMES'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTab({
    required String label,
    required String subLabel,
    required String formatValue,
    required IconData icon,
  }) {
    final bool isSelected = _format == formatValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _format = formatValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? ColorConstants.primary : ColorConstants.mediumText,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? ColorConstants.primary : ColorConstants.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? ColorConstants.primary.withValues(alpha: 0.8) : ColorConstants.subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ColorConstants.primaryLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: ColorConstants.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.darkText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorConstants.mediumText,
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
            fontSize: 16,
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
