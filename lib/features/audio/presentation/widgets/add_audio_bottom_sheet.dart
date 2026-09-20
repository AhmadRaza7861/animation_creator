import 'package:flutter/material.dart';
import 'package:dummy/core/constants/app_colors.dart';

enum AudioAddSource {
  voiceMaker,
  library,
  recorder,
  filePicker,
}

class AddAudioBottomSheet extends StatelessWidget {
  final int defaultTrackIndex;

  const AddAudioBottomSheet({
    super.key,
    this.defaultTrackIndex = 0,
  });

  static Future<AudioAddSource?> show({
    required BuildContext context,
    int defaultTrackIndex = 0,
  }) {
    return showModalBottomSheet<AudioAddSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddAudioBottomSheet(
        defaultTrackIndex: defaultTrackIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Text(
                  'Add Audio to Animation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.darkText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Voice maker
              _buildOptionTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Voice maker',
                subtitle: 'Generate animated character voices & speech',
                onTap: () => Navigator.pop(context, AudioAddSource.voiceMaker),
              ),

              // Option 2: Audio Library
              _buildOptionTile(
                icon: Icons.library_music_rounded,
                title: 'Audio Library',
                subtitle: 'Sound effects, cartoon boings, whooshes & loops',
                onTap: () => Navigator.pop(context, AudioAddSource.library),
              ),

              // Option 3: Audio Recorder
              _buildOptionTile(
                icon: Icons.mic_rounded,
                title: 'Audio Recorder',
                subtitle: 'Record voice-overs directly with microphone',
                onTap: () => Navigator.pop(context, AudioAddSource.recorder),
              ),

              // Option 4: Add Audio (File Picker)
              _buildOptionTile(
                icon: Icons.audio_file_rounded,
                title: 'Add Audio',
                subtitle: 'Import MP3, WAV, AAC from device storage',
                onTap: () => Navigator.pop(context, AudioAddSource.filePicker),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryLight,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: ColorConstants.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: ColorConstants.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColorConstants.mediumText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: ColorConstants.lightText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
