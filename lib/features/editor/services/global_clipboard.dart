import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../../../../core/utils/app_path_provider.dart';
import '../presentation/widgets/sticker_widgets/shape_sticker_widget.dart';

/// Data transfer object holding serialized Lasso selection properties
class LassoClipboardData {
  final Map<String, dynamic> contentJson;
  final Size size;
  final Offset offset;
  final double scale;
  final double rotation;
  final bool flipX;
  final bool flipY;
  final Offset topLeftOffset;
  final Offset topRightOffset;
  final Offset bottomRightOffset;
  final Offset bottomLeftOffset;
  final StickerTransformMode transformMode;

  LassoClipboardData({
    required this.contentJson,
    required this.size,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.flipX,
    required this.flipY,
    required this.topLeftOffset,
    required this.topRightOffset,
    required this.bottomRightOffset,
    required this.bottomLeftOffset,
    required this.transformMode,
  });

  Map<String, dynamic> toJson() => {
    'content': contentJson,
    'size': {'width': size.width, 'height': size.height},
    'offset': {'dx': offset.dx, 'dy': offset.dy},
    'scale': scale,
    'rotation': rotation,
    'flipX': flipX,
    'flipY': flipY,
    'topLeftOffset': {'dx': topLeftOffset.dx, 'dy': topLeftOffset.dy},
    'topRightOffset': {'dx': topRightOffset.dx, 'dy': topRightOffset.dy},
    'bottomRightOffset': {'dx': bottomRightOffset.dx, 'dy': bottomRightOffset.dy},
    'bottomLeftOffset': {'dx': bottomLeftOffset.dx, 'dy': bottomLeftOffset.dy},
    'transformMode': transformMode.index,
  };

  factory LassoClipboardData.fromJson(Map<String, dynamic> json) {
    final sizeMap = json['size'] as Map<String, dynamic>;
    final offsetMap = json['offset'] as Map<String, dynamic>;
    final tlMap = json['topLeftOffset'] as Map<String, dynamic>?;
    final trMap = json['topRightOffset'] as Map<String, dynamic>?;
    final brMap = json['bottomRightOffset'] as Map<String, dynamic>?;
    final blMap = json['bottomLeftOffset'] as Map<String, dynamic>?;

    return LassoClipboardData(
      contentJson: json['content'] as Map<String, dynamic>,
      size: Size((sizeMap['width'] as num).toDouble(), (sizeMap['height'] as num).toDouble()),
      offset: Offset((offsetMap['dx'] as num).toDouble(), (offsetMap['dy'] as num).toDouble()),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      flipX: json['flipX'] as bool? ?? false,
      flipY: json['flipY'] as bool? ?? false,
      topLeftOffset: tlMap != null ? Offset((tlMap['dx'] as num).toDouble(), (tlMap['dy'] as num).toDouble()) : Offset.zero,
      topRightOffset: trMap != null ? Offset((trMap['dx'] as num).toDouble(), (trMap['dy'] as num).toDouble()) : Offset.zero,
      bottomRightOffset: brMap != null ? Offset((brMap['dx'] as num).toDouble(), (brMap['dy'] as num).toDouble()) : Offset.zero,
      bottomLeftOffset: blMap != null ? Offset((blMap['dx'] as num).toDouble(), (blMap['dy'] as num).toDouble()) : Offset.zero,
      transformMode: StickerTransformMode.values[(json['transformMode'] as int?) ?? 0],
    );
  }
}

/// Global Cross-Project Clipboard Service
///
/// Persists copied Lasso selections and Frames in memory and on disk so they
/// remain available across project changes and app restarts.
class GlobalClipboard {
  static final GlobalClipboard instance = GlobalClipboard._();

  GlobalClipboard._() {
    _initPersistence();
  }

  final ValueNotifier<bool> hasLassoContentNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasFrameContentNotifier = ValueNotifier<bool>(false);

  LassoClipboardData? _lassoData;
  Map<String, dynamic>? _frameData;

  bool get hasLassoContent => _lassoData != null;
  bool get hasFrameContent => _frameData != null;

  LassoClipboardData? get lassoData => _lassoData;
  Map<String, dynamic>? get frameData => _frameData;

  Future<void> _initPersistence() async {
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final lassoFile = File('${dir.path}/global_lasso_clipboard.json');
      if (await lassoFile.exists()) {
        final str = await lassoFile.readAsString();
        if (str.isNotEmpty) {
          final json = jsonDecode(str) as Map<String, dynamic>;
          _lassoData = LassoClipboardData.fromJson(json);
          hasLassoContentNotifier.value = true;
        }
      }
      final frameFile = File('${dir.path}/global_frame_clipboard.json');
      if (await frameFile.exists()) {
        final str = await frameFile.readAsString();
        if (str.isNotEmpty) {
          _frameData = jsonDecode(str) as Map<String, dynamic>;
          hasFrameContentNotifier.value = true;
        }
      }
    } catch (e) {
      debugPrint('Error initializing global clipboard: $e');
    }
  }

  Future<void> copyLasso(ActiveShapeSticker sticker) async {
    final data = LassoClipboardData(
      contentJson: sticker.content.toJson(),
      size: sticker.size,
      offset: sticker.offset,
      scale: sticker.scale,
      rotation: sticker.rotation,
      flipX: sticker.flipX,
      flipY: sticker.flipY,
      topLeftOffset: sticker.topLeftOffset,
      topRightOffset: sticker.topRightOffset,
      bottomRightOffset: sticker.bottomRightOffset,
      bottomLeftOffset: sticker.bottomLeftOffset,
      transformMode: sticker.transformMode,
    );
    _lassoData = data;
    hasLassoContentNotifier.value = true;

    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final lassoFile = File('${dir.path}/global_lasso_clipboard.json');
      await lassoFile.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      debugPrint('Error saving global lasso clipboard: $e');
    }
  }

  Future<void> copyFrame(Map<String, dynamic> frameJson) async {
    _frameData = frameJson;
    hasFrameContentNotifier.value = true;

    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final frameFile = File('${dir.path}/global_frame_clipboard.json');
      await frameFile.writeAsString(jsonEncode(frameJson));
    } catch (e) {
      debugPrint('Error saving global frame clipboard: $e');
    }
  }

  void clearLasso() {
    _lassoData = null;
    hasLassoContentNotifier.value = false;
    AppPathProvider.getSafeDocumentsDirectory().then((dir) {
      final lassoFile = File('${dir.path}/global_lasso_clipboard.json');
      if (lassoFile.existsSync()) {
        lassoFile.deleteSync();
      }
    }).catchError((_) {});
  }

  void clearAll() {
    _lassoData = null;
    _frameData = null;
    hasLassoContentNotifier.value = false;
    hasFrameContentNotifier.value = false;
    AppPathProvider.getSafeDocumentsDirectory().then((dir) {
      final lassoFile = File('${dir.path}/global_lasso_clipboard.json');
      if (lassoFile.existsSync()) lassoFile.deleteSync();
      final frameFile = File('${dir.path}/global_frame_clipboard.json');
      if (frameFile.existsSync()) frameFile.deleteSync();
    }).catchError((_) {});
  }
}
