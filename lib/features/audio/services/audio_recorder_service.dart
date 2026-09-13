import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../../../../core/utils/app_path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _currentFilePath;
  final List<double> _liveAmplitudes = [];
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  bool get isRecording => _isRecording;
  List<double> get liveAmplitudes => List.unmodifiable(_liveAmplitudes);

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('Error checking audio recording permission: $e');
      return false;
    }
  }

  Future<String?> startRecording({void Function(double amplitude)? onAmplitude}) async {
    try {
      if (!await hasPermission()) {
        return null;
      }

      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final audioDir = Directory('${dir.path}/recordings');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentFilePath = '${audioDir.path}/$fileName';
      _liveAmplitudes.clear();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 80))
          .listen((amp) {
        // dBFS normalized from -60..0 to 0.0..1.0
        final double normalized = ((amp.current + 60.0) / 60.0).clamp(0.05, 1.0);
        _liveAmplitudes.add(normalized);
        onAmplitude?.call(normalized);
      });

      return _currentFilePath;
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<RecordedAudioResult?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      final path = await _recorder.stop();
      _isRecording = false;

      final durationMs = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
          : 0;

      final List<double> samples = _liveAmplitudes.isNotEmpty
          ? List<double>.from(_liveAmplitudes)
          : List.generate(60, (i) => 0.3);

      return RecordedAudioResult(
        filePath: path ?? _currentFilePath ?? '',
        durationMs: durationMs > 500 ? durationMs : 1000,
        waveformSamples: samples,
      );
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        if (_currentFilePath != null) {
          final file = File(_currentFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (_) {}
  }

  void dispose() {
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
  }
}

class RecordedAudioResult {
  final String filePath;
  final int durationMs;
  final List<double> waveformSamples;

  RecordedAudioResult({
    required this.filePath,
    required this.durationMs,
    required this.waveformSamples,
  });
}
