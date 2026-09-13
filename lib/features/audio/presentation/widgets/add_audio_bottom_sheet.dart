import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../domain/models/audio_clip.dart';
import '../screens/audio_library_screen.dart';
import '../screens/audio_recorder_screen.dart';
import '../screens/audio_trimmer_screen.dart';
import '../screens/voice_maker_screen.dart';

class AddAudioBottomSheet extends StatelessWidget {
  final int defaultTrackIndex;
  final void Function(AudioClip clip) onAudioClipAdded;

  const AddAudioBottomSheet({
    super.key,
    required this.defaultTrackIndex,
    required this.onAudioClipAdded,
  });

  static Future<void> show({
    required BuildContext context,
    required int defaultTrackIndex,
    required void Function(AudioClip clip) onAudioClipAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddAudioBottomSheet(
        defaultTrackIndex: defaultTrackIndex,
        onAudioClipAdded: onAudioClipAdded,
      ),
    );
  }

  void _openFilePicker(BuildContext context) async {
    Navigator.pop(context);
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        final pickedFile = result.first;
        final file = File(pickedFile.path!);
        final clip = AudioClip(
          title: pickedFile.name.split('.').first,
          filePath: file.path,
          trackIndex: defaultTrackIndex,
          durationMs: 3000, // Default duration, will be refined in trimmer
        );

        if (!context.mounted) return;
        final trimmed = await Navigator.push<AudioClip>(
          context,
          MaterialPageRoute(
            builder: (context) => AudioTrimmerScreen(clip: clip),
          ),
        );

        if (trimmed != null) {
          onAudioClipAdded(trimmed);
        }
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
  }

  void _openVoiceMaker(BuildContext context) async {
    Navigator.pop(context);
    final clip = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceMakerScreen(defaultTrackIndex: defaultTrackIndex),
      ),
    );
    if (clip != null) {
      onAudioClipAdded(clip);
    }
  }

  void _openAudioLibrary(BuildContext context) async {
    Navigator.pop(context);
    final clip = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioLibraryScreen(defaultTrackIndex: defaultTrackIndex),
      ),
    );
    if (clip != null) {
      onAudioClipAdded(clip);
    }
  }

  void _openAudioRecorder(BuildContext context) async {
    Navigator.pop(context);
    final clip = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioRecorderScreen(defaultTrackIndex: defaultTrackIndex),
      ),
    );
    if (clip != null) {
      onAudioClipAdded(clip);
    }
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
              onTap: () => _openVoiceMaker(context),
            ),

            // Option 2: Audio Library
            _buildOptionTile(
              icon: Icons.library_music_rounded,
              title: 'Audio Library',
              subtitle: 'Sound effects, cartoon boings, whooshes & loops',
              onTap: () => _openAudioLibrary(context),
            ),

            // Option 3: Audio Recorder
            _buildOptionTile(
              icon: Icons.mic_rounded,
              title: 'Audio Recorder',
              subtitle: 'Record voice-overs directly with microphone',
              onTap: () => _openAudioRecorder(context),
            ),

            // Option 4: Add Audio (File Picker)
            _buildOptionTile(
              icon: Icons.audio_file_rounded,
              title: 'Add Audio',
              subtitle: 'Import MP3, WAV, AAC from device storage',
              onTap: () => _openFilePicker(context),
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
                    color: const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF4B72), size: 24),
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
