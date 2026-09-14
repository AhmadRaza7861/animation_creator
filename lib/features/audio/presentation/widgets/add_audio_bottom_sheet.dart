import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E24),
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

            const SizedBox(height: 8),
          ],
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
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF9318), size: 24),
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
                          color: Color(0xFF1E1E24),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
