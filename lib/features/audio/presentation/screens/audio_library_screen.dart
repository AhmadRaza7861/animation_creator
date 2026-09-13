import 'package:flutter/material.dart';
import '../../domain/models/audio_clip.dart';
import '../../services/audio_library_service.dart';
import '../../services/audio_playback_service.dart';
import 'audio_trimmer_screen.dart';

class AudioLibraryScreen extends StatefulWidget {
  final int defaultTrackIndex;

  const AudioLibraryScreen({
    super.key,
    this.defaultTrackIndex = 0,
  });

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  final AudioPlaybackService _playbackService = AudioPlaybackService();
  String _selectedCategory = 'All';
  String? _currentlyPlayingId;

  final List<String> _categories = ['All', 'Cartoon', 'Action', 'Game', 'Magic', 'Music'];

  @override
  void dispose() {
    _playbackService.dispose();
    super.dispose();
  }

  void _previewItem(AudioLibraryItem item) async {
    if (_currentlyPlayingId == item.id) {
      await _playbackService.stopAll();
      setState(() {
        _currentlyPlayingId = null;
      });
      return;
    }

    setState(() {
      _currentlyPlayingId = item.id;
    });

    final clip = await AudioLibraryService.generateOrGetClip(item);
    await _playbackService.playSingleClip(clip, onComplete: () {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });
  }

  void _selectItem(AudioLibraryItem item) async {
    await _playbackService.stopAll();
    final clip = await AudioLibraryService.generateOrGetClip(item);
    final clipWithTrack = clip.copyWith(trackIndex: widget.defaultTrackIndex);

    if (!mounted) return;
    final trimmed = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioTrimmerScreen(clip: clipWithTrack),
      ),
    );

    if (trimmed != null && mounted) {
      Navigator.pop(context, trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? AudioLibraryService.libraryItems
        : AudioLibraryService.libraryItems.where((i) => i.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E24)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Audio Library',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E24),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Chips Row
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      selectedColor: const Color(0xFFFF4B72),
                      backgroundColor: const Color(0xFFF0F1F5),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF2C2D35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEBEBF0)),

            // Sound Effects List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isPlaying = _currentlyPlayingId == item.id;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPlaying
                            ? const Color(0xFFFF4B72).withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Category Emoji / Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              item.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1E24),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(item.durationMs / 1000).toStringAsFixed(1)}s • ${item.description}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Play Preview Button
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            color: const Color(0xFFFF4B72),
                            size: 34,
                          ),
                          onPressed: () => _previewItem(item),
                        ),

                        // Add Button
                        ElevatedButton(
                          onPressed: () => _selectItem(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4B72),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
