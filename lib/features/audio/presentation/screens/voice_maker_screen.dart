import 'package:flutter/material.dart';
import '../../domain/models/audio_clip.dart';
import '../../services/audio_playback_service.dart';
import '../../services/voice_maker_service.dart';
import 'audio_trimmer_screen.dart';

class VoiceMakerScreen extends StatefulWidget {
  final int defaultTrackIndex;

  const VoiceMakerScreen({
    super.key,
    this.defaultTrackIndex = 0,
  });

  @override
  State<VoiceMakerScreen> createState() => _VoiceMakerScreenState();
}

class _VoiceMakerScreenState extends State<VoiceMakerScreen> {
  final AudioPlaybackService _playbackService = AudioPlaybackService();
  late TextEditingController _textController;

  VoiceStylePreset _selectedPreset = VoiceMakerService.presets.first;
  double _speed = 1.0;
  double _pitch = 1.0;
  bool _isSynthesizing = false;
  bool _isPlaying = false;
  AudioClip? _previewClip;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _selectedPreset.sampleText);
  }

  @override
  void dispose() {
    _playbackService.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _selectPreset(VoiceStylePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _textController.text = preset.sampleText;
      _previewClip = null;
    });
  }

  Future<AudioClip?> _generateClip() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter speech text to generate voice.')),
      );
      return null;
    }

    setState(() {
      _isSynthesizing = true;
    });

    try {
      final clip = await VoiceMakerService.synthesizeVoiceClip(
        text: text,
        preset: _selectedPreset,
        speed: _speed,
        pitch: _pitch,
      );
      _previewClip = clip.copyWith(trackIndex: widget.defaultTrackIndex);
      return _previewClip;
    } catch (e) {
      debugPrint('Error synthesizing voice: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isSynthesizing = false;
        });
      }
    }
  }

  void _previewVoice() async {
    if (_isPlaying) {
      await _playbackService.stopAll();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    final clip = _previewClip ?? await _generateClip();
    if (clip == null || !mounted) return;

    setState(() {
      _isPlaying = true;
    });

    await _playbackService.playSingleClip(clip, onComplete: () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _addToTimeline() async {
    final clip = _previewClip ?? await _generateClip();
    if (clip == null || !mounted) return;

    final trimmed = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioTrimmerScreen(clip: clip),
      ),
    );

    if (trimmed != null && mounted) {
      Navigator.pop(context, trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Voice Maker (TTS)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E24),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice Preset Selector
              const Text(
                'Character Voice Style',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E1E24)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: VoiceMakerService.presets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = VoiceMakerService.presets[index];
                    final isSelected = preset.id == _selectedPreset.id;

                    return GestureDetector(
                      onTap: () => _selectPreset(preset),
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF4E8) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF9318) : Colors.black.withValues(alpha: 0.08),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(preset.icon, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? const Color(0xFFFF9318) : const Color(0xFF1E1E24),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Speech Text Input
              const Text(
                'Speech Text',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E1E24)),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 3,
                  onChanged: (_) {
                    _previewClip = null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type words for your animated character to speak...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Voice Modifiers (Pitch & Speed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pitch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${_pitch.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF9318))),
                      ],
                    ),
                    Slider(
                      value: _pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      activeColor: const Color(0xFFFF9318),
                      onChanged: (val) {
                        setState(() {
                          _pitch = val;
                          _previewClip = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${_speed.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF9318))),
                      ],
                    ),
                    Slider(
                      value: _speed,
                      min: 0.6,
                      max: 1.8,
                      divisions: 12,
                      activeColor: const Color(0xFFFF9318),
                      onChanged: (val) {
                        setState(() {
                          _speed = val;
                          _previewClip = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Action Buttons Row
              Row(
                children: [
                  // Preview Button
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isSynthesizing ? null : _previewVoice,
                        icon: Icon(
                          _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFFFF9318),
                        ),
                        label: Text(
                          _isPlaying ? 'Stop' : 'Preview',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF9318)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF9318), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Add to timeline Button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSynthesizing ? null : _addToTimeline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9318),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: _isSynthesizing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Add to timeline',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
