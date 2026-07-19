import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dummy/package_code/src/drawing_bar/default_action_item.dart';
import 'package:dummy/package_code/src/drawing_bar/default_tool_item.dart';
import 'package:dummy/package_code/src/ruler/ruler_config.dart';
import 'package:dummy/package_code/src/drawing_bar/drawing_bar.dart';
import 'package:dummy/package_code/src/drawing_board.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_extension/ex_paint.dart';
import 'package_code/src/paint_contents/simple_line.dart'; // SimpleLine and FreehandLine are here

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package_code/paint_contents.dart';
import 'package_code/src/paint_contents/layer_data.dart';
import 'package_code/src/paint_contents/paint_content_decoder.dart';
import 'widgets/text_sticker_widget.dart';
import 'widgets/shape_sticker_widget.dart';
import 'widgets/straight_line_sticker_widget.dart';
import 'widgets/freehand_line_sticker_widget.dart'; // Added new import
import 'widgets/layer_panel.dart';
import 'widgets/canvas_selector.dart';
import 'screens/animation_preview_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/frames_reorder_screen.dart';
import 'repositories/project_repository.dart';
import 'screens/projects_screen.dart';
import 'screens/video_trimming_screen.dart';
import 'screens/splash_screen.dart';

Future<ui.Image> _getImage(String path) async {
  final Completer<ImageInfo> completer = Completer<ImageInfo>();
  final NetworkImage img = NetworkImage(path);
  img
      .resolve(ImageConfiguration.empty)
      .addListener(
        ImageStreamListener((ImageInfo info, _) {
          completer.complete(info);
        }),
      );

  final ImageInfo imageInfo = await completer.future;

  return imageInfo.image;
}

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) {
      exit(1);
    }
  };

  runApp(MyApp(repository: ProjectRepository()));
}

class CanvasBackground {
  final Color color;
  final ui.Image? image;
  final String? imagePath;
  final double imageOpacity;
  final String? pattern;

  CanvasBackground({
    this.color = Colors.white,
    this.image,
    this.imagePath,
    this.imageOpacity = 1.0,
    this.pattern,
  });

  CanvasBackground copyWith({
    Color? color,
    ui.Image? image,
    String? imagePath,
    double? imageOpacity,
    String? pattern,
    bool clearImage = false,
  }) {
    return CanvasBackground(
      color: color ?? this.color,
      image: clearImage ? null : (image ?? this.image),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      imageOpacity: imageOpacity ?? this.imageOpacity,
      pattern: clearImage ? null : (pattern ?? this.pattern),
    );
  }
}

class MyApp extends StatelessWidget {
  final ProjectRepository repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clipax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Outfit',
      ),
      home: SplashScreen(repository: repository),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ProjectRepository repository;
  final String? projectId;

  const MyHomePage({super.key, required this.repository, this.projectId});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  /// 所有画布及其快照
  final List<DrawingController> _canvases = [];
  final List<ui.Image?> _thumbnails = [];
  CanvasBackground _globalBackground = CanvasBackground();
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();

  Future<ui.Image> _getFileImage(String path) async {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    final FileImage img = FileImage(File(path));
    img
        .resolve(ImageConfiguration.empty)
        .addListener(
          ImageStreamListener((ImageInfo info, _) {
            completer.complete(info);
          }),
        );
    final ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }

  DrawingController get _drawingController => _canvases[_currentIndex];

  final TransformationController _transformationController =
      TransformationController();
  Object? _activeStickerBacking;
  Object? get _activeSticker => _activeStickerBacking;
  set _activeSticker(Object? value) {
    if (_activeStickerBacking == value) return;
    _activeStickerBacking = value;
    if (value == null) {
      _clearActiveStickerHistory();
    } else {
      _initActiveStickerHistory(value);
      _undoneSticker = null;
      _undoneStickerHistory.clear();
      _undoneStickerHistoryIndex = -1;
    }
  }

  List<Object> _activeStickerHistory = [];
  int _activeStickerHistoryIndex = -1;

  Object? _undoneSticker;
  List<Object> _undoneStickerHistory = [];
  int _undoneStickerHistoryIndex = -1;

  bool _isUndoingActiveStickerPlacement = false;

  Object cloneActiveSticker(Object sticker) {
    if (sticker is ActiveTextSticker) {
      return ActiveTextSticker(
        id: sticker.id,
        text: sticker.text,
        color: sticker.color,
        fontSize: sticker.fontSize,
        offset: sticker.offset,
        scale: sticker.scale,
        rotation: sticker.rotation,
        isBold: sticker.isBold,
        fontFamily: sticker.fontFamily,
      );
    } else if (sticker is ActiveShapeSticker) {
      return ActiveShapeSticker(
        id: sticker.id,
        content: sticker.content.copy(),
        size: sticker.size,
        offset: sticker.offset,
        scale: sticker.scale,
        rotation: sticker.rotation,
      );
    } else if (sticker is ActiveStraightLineSticker) {
      return ActiveStraightLineSticker(
        id: sticker.id,
        startPoint: sticker.startPoint,
        endPoint: sticker.endPoint,
        paint: sticker.paint.copyWith(),
        type: sticker.type,
      );
    } else if (sticker is ActiveFreehandLineSticker) {
      return ActiveFreehandLineSticker(
        id: sticker.id,
        content: sticker.content.copy() as FreehandLine,
      );
    }
    throw ArgumentError('Unknown sticker type: ${sticker.runtimeType}');
  }

  bool _isStickerStateDifferent(Object a, Object b) {
    if (a.runtimeType != b.runtimeType) return true;
    if (a is ActiveTextSticker && b is ActiveTextSticker) {
      return a.text != b.text ||
          a.color != b.color ||
          a.fontSize != b.fontSize ||
          a.offset != b.offset ||
          a.scale != b.scale ||
          a.rotation != b.rotation ||
          a.isBold != b.isBold ||
          a.fontFamily != b.fontFamily;
    }
    if (a is ActiveShapeSticker && b is ActiveShapeSticker) {
      return a.offset != b.offset ||
          a.scale != b.scale ||
          a.rotation != b.rotation ||
          a.size != b.size;
    }
    if (a is ActiveStraightLineSticker && b is ActiveStraightLineSticker) {
      return a.startPoint != b.startPoint || a.endPoint != b.endPoint;
    }
    if (a is ActiveFreehandLineSticker && b is ActiveFreehandLineSticker) {
      if (a.content.points?.length != b.content.points?.length) return true;
      if (a.content.points == null || b.content.points == null) return false;
      for (int i = 0; i < a.content.points!.length; i++) {
        if (a.content.points![i] != b.content.points![i]) return true;
      }
      return false;
    }
    return false;
  }

  void _initActiveStickerHistory(Object sticker) {
    _activeStickerHistory = [cloneActiveSticker(sticker)];
    _activeStickerHistoryIndex = 0;

    _drawingController.onUndo = _undoActiveSticker;
    _drawingController.onRedo = _redoActiveSticker;
    _drawingController.onCanUndo = _canUndoActiveSticker;
    _drawingController.onCanRedo = _canRedoActiveSticker;
    _drawingController.refresh();
  }

  void _clearActiveStickerHistory() {
    _activeStickerHistory.clear();
    _activeStickerHistoryIndex = -1;

    if (!_isUndoingActiveStickerPlacement) {
      _undoneSticker = null;
      _undoneStickerHistory.clear();
      _undoneStickerHistoryIndex = -1;
    }

    if (_undoneSticker == null) {
      _drawingController.onUndo = null;
      _drawingController.onRedo = null;
      _drawingController.onCanUndo = null;
      _drawingController.onCanRedo = null;
    } else {
      _drawingController.onUndo = _undoFallback;
      _drawingController.onRedo = _redoFallback;
      _drawingController.onCanUndo = _canUndoFallback;
      _drawingController.onCanRedo = _canRedoFallback;
    }
    _drawingController.refresh();
  }

  void _recordActiveStickerState() {
    final sticker = _activeSticker;
    if (sticker == null) return;

    final newState = cloneActiveSticker(sticker);

    if (_activeStickerHistoryIndex >= 0 &&
        _activeStickerHistoryIndex < _activeStickerHistory.length) {
      final currentState = _activeStickerHistory[_activeStickerHistoryIndex];
      if (!_isStickerStateDifferent(newState, currentState)) {
        return;
      }
    }

    if (_activeStickerHistoryIndex < _activeStickerHistory.length - 1) {
      _activeStickerHistory.removeRange(
        _activeStickerHistoryIndex + 1,
        _activeStickerHistory.length,
      );
    }

    _activeStickerHistory.add(newState);
    _activeStickerHistoryIndex = _activeStickerHistory.length - 1;

    _drawingController.refresh();
  }

  void _undoActiveSticker() {
    if (_activeStickerHistoryIndex > 0) {
      setState(() {
        _activeStickerHistoryIndex--;
        _activeStickerBacking = cloneActiveSticker(
          _activeStickerHistory[_activeStickerHistoryIndex],
        );
      });
      _updateSnapshot();
      _drawingController.refresh();
    } else if (_activeStickerHistoryIndex == 0) {
      _isUndoingActiveStickerPlacement = true;
      setState(() {
        _undoneSticker = _activeSticker;
        _undoneStickerHistory = List.from(_activeStickerHistory);
        _undoneStickerHistoryIndex = _activeStickerHistoryIndex;
        _activeStickerBacking = null;
      });
      _clearActiveStickerHistory();
      _isUndoingActiveStickerPlacement = false;
      _updateSnapshot();
      _drawingController.refresh();
    }
  }

  void _redoActiveSticker() {
    if (_activeStickerHistoryIndex < _activeStickerHistory.length - 1) {
      setState(() {
        _activeStickerHistoryIndex++;
        _activeStickerBacking = cloneActiveSticker(
          _activeStickerHistory[_activeStickerHistoryIndex],
        );
      });
      _updateSnapshot();
      _drawingController.refresh();
    }
  }

  bool _canUndoActiveSticker() {
    return true;
  }

  bool _canRedoActiveSticker() {
    return _activeStickerHistoryIndex < _activeStickerHistory.length - 1;
  }

  void _undoFallback() {
    _drawingController.onUndo = null;
    _drawingController.undo();
    setState(() {
      _undoneSticker = null;
      _undoneStickerHistory.clear();
      _undoneStickerHistoryIndex = -1;
    });
    _clearActiveStickerHistory();
  }

  void _redoFallback() {
    setState(() {
      _activeStickerBacking = _undoneSticker;
      _activeStickerHistory = List.from(_undoneStickerHistory);
      _activeStickerHistoryIndex = _undoneStickerHistoryIndex;
      _undoneSticker = null;
      _undoneStickerHistory.clear();
      _undoneStickerHistoryIndex = -1;
    });
    _drawingController.onUndo = _undoActiveSticker;
    _drawingController.onRedo = _redoActiveSticker;
    _drawingController.onCanUndo = _canUndoActiveSticker;
    _drawingController.onCanRedo = _canRedoActiveSticker;
    _updateSnapshot();
    _drawingController.refresh();
  }

  bool _canUndoFallback() {
    final layer = _drawingController.activeLayer.value;
    if (layer == null || layer.isLocked) return false;
    return layer.currentIndex > 0;
  }

  bool _canRedoFallback() {
    return true;
  }

  bool _showRulerMenu = false;
  bool _showLayerPanel = false;

  double _colorOpacity = 1;

  double? _aspectRatio;
  int _fps = 9;
  String? _savedJsonData;

  void _onDrawConfigChanged() {
    final drawConfig = _drawingController.drawConfig.value;
    final bool isPenTools =
        drawConfig.contentType == FreehandLine ||
        drawConfig.contentType == SmoothLine;

    // Auto-disable Ruler overlay and menu if switching out of pen tools
    if (!isPenTools && _showRulerMenu) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showRulerMenu = false;
          _drawingController.rulerConfig.value = _drawingController
              .rulerConfig
              .value
              .copyWith(type: RulerType.none);
        });
      });
    }
  }

  Widget _buildFloatingRulerMenu() {
    return ValueListenableBuilder<RulerConfig>(
      valueListenable: _drawingController.rulerConfig,
      builder: (context, config, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _floatingRulerButton(
                'LOCK',
                Icons.lock_outline,
                RulerType.none,
                config,
                isLock: true,
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              _floatingRulerButton(
                'LINE',
                Icons.horizontal_rule,
                RulerType.line,
                config,
              ),
              _floatingRulerButton(
                'CIRC',
                Icons.circle_outlined,
                RulerType.circle,
                config,
              ),
              _floatingRulerButton(
                'BOX',
                Icons.crop_square,
                RulerType.box,
                config,
              ),
              _floatingRulerButton(
                'MIRR',
                Icons.flip,
                RulerType.mirror,
                config,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _floatingRulerButton(
    String label,
    IconData icon,
    RulerType type,
    RulerConfig config, {
    bool isLock = false,
  }) {
    final isSelected = isLock ? config.isLocked : config.type == type;
    final color = isSelected ? Colors.pinkAccent : Colors.black87;

    return GestureDetector(
      onTap: () {
        if (isLock) {
          _drawingController.rulerConfig.value = config.copyWith(
            isLocked: !config.isLocked,
          );
        } else {
          _drawingController.rulerConfig.value = config.copyWith(type: type);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingRightToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: ValueListenableBuilder<DrawConfig>(
        valueListenable: _drawingController.drawConfig,
        builder: (context, drawConfig, child) {
          final bool isPenTools =
              drawConfig.contentType == FreehandLine ||
              drawConfig.contentType == SmoothLine;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rightToolbarItem(
                'GALLERY',
                Icons.collections_bookmark,
                false,
                _openGallery,
                iconColor: Colors.blueAccent,
              ),
              // const SizedBox(height: 16),
              // _rightToolbarItem('BRUSH', Icons.brush, false, () {}),
              // const SizedBox(height: 16),
              // _rightToolbarItem(
              //   'SIZE',
              //   Icons.circle,
              //   false,
              //   () {},
              //   iconSize: 10,
              // ),
              // const SizedBox(height: 16),
              // _rightToolbarItem(
              //   'COLOR',
              //   Icons.square,
              //   false,
              //   () {},
              //   iconColor: Colors.pinkAccent,
              // ),
              const SizedBox(height: 16),
              _rightToolbarItem(
                'BG',
                Icons.wallpaper_rounded,
                false,
                _showBackgroundSettings,
                iconColor: Colors.orangeAccent,
              ),
              if (isPenTools) ...[
                Container(
                  width: 24,
                  height: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
                _rightToolbarItem(
                  'RULER',
                  Icons.straighten,
                  _showRulerMenu,
                  () {
                    setState(() {
                      _showRulerMenu = !_showRulerMenu;
                      if (!_showRulerMenu) {
                        _drawingController.rulerConfig.value =
                            _drawingController.rulerConfig.value.copyWith(
                              type: RulerType.none,
                            );
                      } else {
                        _drawingController.rulerConfig.value =
                            _drawingController.rulerConfig.value.copyWith(
                              type: RulerType.line,
                            );
                      }
                    });
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _rightToolbarItem(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap, {
    double iconSize = 24,
    Color? iconColor,
  }) {
    final color = isSelected ? Colors.pinkAccent : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? color, size: iconSize),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _updateSnapshot() {
    // 捕获当前画布的快照并更新缩略图
    // We intentionally don't pass active sticker here anymore to prevent it showing in the bottom gallery
    _drawingController.updateSnapshot(includeBackground: false);
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.projectId != null) {
      _loadProjectData();
    } else {
      _addNewCanvas(initial: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAspectRatioDialog();
      });
    }
    _scrollController.addListener(_onScroll);
  }

  bool _isLoadingProject = false;
  String? _currentProjectId;
  Map<String, dynamic>? _clipboardFrame;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProject();
    for (var controller in _canvases) {
      controller.drawConfig.removeListener(_onDrawConfigChanged);
      controller.dispose();
    }
    _transformationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveProject();
    }
  }

  Future<DrawingController> _createControllerFromData(
    Map<String, dynamic> cMap,
  ) async {
    final controller = DrawingController();
    controller.backgroundColor = Color(cMap['backgroundColor'] as int);

    if (cMap['size'] != null) {
      final sMap = cMap['size'] as Map<String, dynamic>;
      controller.drawConfig.value = controller.drawConfig.value.copyWith(
        size: Size(
          (sMap['width'] as num).toDouble(),
          (sMap['height'] as num).toDouble(),
        ),
      );
    }

    final layersData = cMap['layers'] as List<dynamic>;
    controller.layers.clear();
    for (final lData in layersData) {
      final lMap = lData as Map<String, dynamic>;

      final historyData = lMap['history'] as List<dynamic>;
      final List<PaintContent> history = [];
      for (final hData in historyData) {
        final hMap = hData as Map<String, dynamic>;
        final content = decodePaintContent(hMap['type'] as String, hMap);
        if (content != null) {
          await _rehydrateContent(content, hMap);
          history.add(content);
        }
      }

      controller.layers.add(
        LayerData(
          id: lMap['id'] as String,
          name: lMap['name'] as String,
          isVisible: lMap['isVisible'] as bool,
          isLocked: lMap['isLocked'] as bool,
          opacity: (lMap['opacity'] as num).toDouble(),
          blendMode: BlendMode.values[lMap['blendMode'] as int],
          history: history,
          currentIndex: lMap['currentIndex'] as int,
        ),
      );
    }

    final activeLayerId = cMap['activeLayerId'] as String?;
    if (activeLayerId != null && controller.layers.isNotEmpty) {
      final matchedLayer = controller.layers
          .where((l) => l.id == activeLayerId)
          .firstOrNull;
      if (matchedLayer != null) {
        controller.activeLayer.value = matchedLayer;
      } else {
        controller.activeLayer.value = controller.layers.first;
      }
    } else if (controller.layers.isNotEmpty) {
      controller.activeLayer.value = controller.layers.first;
    }

    // Finalize controller setup
    controller.drawConfig.addListener(_onDrawConfigChanged);
    controller.interceptDraw = _createInterceptDraw(controller);
    controller.realTimeSnapshot.addListener(() {
      if (!mounted) return;
      final idx = _canvases.indexOf(controller);
      if (idx != -1) {
        setState(() {
          _thumbnails[idx] = controller.realTimeSnapshot.value;
        });
      }
    });

    return controller;
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoadingProject = true;
    });

    _currentProjectId = widget.projectId;
    final data = await widget.repository.loadProject(widget.projectId!);

    if (data != null && data.state['canvases'] != null) {
      if (data.state.containsKey('aspectRatio')) {
        _aspectRatio = data.state['aspectRatio'] as double?;
      }
      if (data.state.containsKey('fps')) {
        _fps = data.state['fps'] as int;
      }

      // Restore background
      final bgMap = data.state['globalBackground'] as Map<String, dynamic>?;
      if (bgMap != null) {
        _globalBackground = _globalBackground.copyWith(
          color: Color(bgMap['color'] as int),
          imagePath: bgMap['imagePath'] as String?,
          imageOpacity: bgMap['imageOpacity'] as double,
          pattern: bgMap['pattern'] as String?,
        );
        if (_globalBackground.imagePath != null) {
          try {
            final bytes = await File(
              _globalBackground.imagePath!,
            ).readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            _globalBackground = _globalBackground.copyWith(image: frame.image);
          } catch (e) {
            debugPrint('Failed to load bg image: $e');
          }
        }
      }

      // Rehydrate canvases.
      _canvases.clear();
      _thumbnails.clear();
      final canvasesList = data.state['canvases'] as List<dynamic>;
      for (final canvasData in canvasesList) {
        final cMap = canvasData as Map<String, dynamic>;
        final controller = await _createControllerFromData(cMap);

        _canvases.add(controller);
        _thumbnails.add(null);
      }

      if (_canvases.isEmpty) {
        _addNewCanvas(initial: true);
      } else {
        _currentIndex = 0;
        _activeSticker = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (var controller in _canvases) {
            controller.forceRefreshLayers();
            controller.updateSnapshot(includeBackground: false);
          }
        });
      }
    } else {
      _addNewCanvas(initial: true);
    }

    setState(() {
      _isLoadingProject = false;
    });
  }

  Future<void> _saveProject() async {
    if (_canvases.isEmpty) return;

    final Map<String, dynamic> state = {
      'globalBackground': {
        'color': _globalBackground.color.value,
        'imagePath': _globalBackground.imagePath,
        'imageOpacity': _globalBackground.imageOpacity,
        'pattern': _globalBackground.pattern,
      },
      'aspectRatio': _aspectRatio,
      'fps': _fps,
      'canvases': [],
    };

    final List<Map<String, dynamic>> canvasesData = [];
    for (final controller in _canvases) {
      final size = controller.drawConfig.value.size ?? Size.zero;
      canvasesData.add({
        'size': {'width': size.width, 'height': size.height},
        'backgroundColor': controller.backgroundColor.value,
        'layers': await controller.getLayersConfig(),
        'activeLayerId': controller.activeLayer.value?.id,
      });
    }
    state['canvases'] = canvasesData;

    List<int>? thumbBytes;
    if (_canvases.isNotEmpty) {
      final ui.Image? firstFrameImage = await _canvases.first.captureFullImage(
        backgroundColor: _globalBackground.color,
        maxDimension: 256.0,
        backgroundImage: _globalBackground.image,
        backgroundImageOpacity: _globalBackground.imageOpacity,
      );
      if (firstFrameImage != null) {
        final byteData = await firstFrameImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          thumbBytes = byteData.buffer.asUint8List();
        }
      }
    }

    _currentProjectId = await widget.repository.saveProject(
      projectId: _currentProjectId,
      state: state,
      thumbnailBytes: thumbBytes,
    );
  }

  void _onScroll() {
    //
  }

  void _addNewCanvas({bool initial = false}) {
    _insertNewCanvas(_canvases.length, initial: initial);
  }

  void _insertNewCanvas(int index, {bool initial = false}) {
    final newController = DrawingController();
    newController.backgroundColor = Colors.white;
    if (_canvases.isNotEmpty) {
      newController.drawConfig.value = newController.drawConfig.value.copyWith(
        size: _canvases.first.drawConfig.value.size,
      );
    }
    newController.drawConfig.addListener(_onDrawConfigChanged);
    newController.interceptDraw = _createInterceptDraw(newController);

    newController.realTimeSnapshot.addListener(() {
      if (!mounted) return;
      final idx = _canvases.indexOf(newController);
      if (idx != -1) {
        setState(() {
          _thumbnails[idx] = newController.realTimeSnapshot.value;
        });
      }
    });

    if (!initial && _activeSticker != null) {
      _stampActiveSticker();
    }

    setState(() {
      _canvases.insert(index, newController);
      _thumbnails.insert(index, null);
      if (!initial) {
        if (_currentIndex >= index) {
          _currentIndex++; // Push the active index forward if it was at or after the insertion point
        }
        _currentIndex = index; // Select the newly inserted canvas
      }
    });

    if (!initial) {
      _updateSnapshot();
    }
  }

  void _selectCanvas(int index) {
    if (index == _currentIndex) return;

    // Auto-commit any active sticker before switching away
    if (_activeSticker != null) {
      _stampActiveSticker();
    }

    setState(() {
      _currentIndex = index;
    });

    _updateSnapshot();
  }

  void _reorderCanvas(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    setState(() {
      final controller = _canvases.removeAt(oldIndex);
      final thumb = _thumbnails.removeAt(oldIndex);

      _canvases.insert(newIndex, controller);
      _thumbnails.insert(newIndex, thumb);

      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
      } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
        _currentIndex--;
      } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
        _currentIndex++;
      }
    });
  }

  Future<void> _onFrameAction(String action, int index) async {
    if (index < 0 || index >= _canvases.length) return;

    if (action == 'copy') {
      final controller = _canvases[index];
      final size = controller.drawConfig.value.size ?? Size.zero;
      final Map<String, dynamic> data = {
        'size': {'width': size.width, 'height': size.height},
        'backgroundColor': controller.backgroundColor.value,
        'layers': await controller.getLayersConfig(),
        'activeLayerId': controller.activeLayer.value?.id,
      };
      _clipboardFrame = data;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Frame copied!')));
      }
    } else if (action == 'paste') {
      if (_clipboardFrame == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      final newController = await _createControllerFromData(_clipboardFrame!);
      if (mounted) Navigator.pop(context);

      final oldController = _canvases[index];
      setState(() {
        _canvases[index] = newController;
        _thumbnails[index] = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        newController.forceRefreshLayers();
        newController.updateSnapshot(includeBackground: false);
      });

      oldController.drawConfig.removeListener(_onDrawConfigChanged);
      oldController.dispose();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Frame pasted!')));
      }
    } else if (action == 'left') {
      _insertNewCanvas(index); // Inserts before the current index
    } else if (action == 'right') {
      _insertNewCanvas(index + 1); // Inserts after the current index
    } else if (action == 'delete') {
      if (_canvases.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete the last frame')),
        );
        return;
      }
      final oldController = _canvases[index];
      setState(() {
        _canvases.removeAt(index);
        _thumbnails.removeAt(index);
        if (_currentIndex == index) {
          _currentIndex = (index > 0) ? index - 1 : 0;
        } else if (_currentIndex > index) {
          _currentIndex--;
        }
      });
      oldController.drawConfig.removeListener(_onDrawConfigChanged);
      oldController.dispose();
      _updateSnapshot();
    }
  }

  Future<void> _openFramesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FramesReorderScreen(
          thumbnails: _thumbnails,
          currentIndex: _currentIndex,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final List<int> newOrder = result['order'];
      final int newActive = result['active'];

      setState(() {
        final List<DrawingController> newCanvases = [];
        final List<ui.Image?> newThumbs = [];
        for (final index in newOrder) {
          newCanvases.add(_canvases[index]);
          newThumbs.add(_thumbnails[index]);
        }
        _canvases.clear();
        _canvases.addAll(newCanvases);
        _thumbnails.clear();
        _thumbnails.addAll(newThumbs);

        _currentIndex = newActive;
      });
      _updateSnapshot();
    }
  }

  Future<void> _importVideo() async {
    if (_drawingController.isCurrentLayerLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Current layer is locked.')));
      return;
    }

    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoTrimmingScreen(videoFile: File(video.path)),
      ),
    );

    if (result != null && result is List<String>) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      try {
        final List<ui.Image> decodedImages = [];
        for (final path in result) {
          final ui.Image img = await _getFileImage(path);
          decodedImages.add(img);
        }

        final Size baseSize =
            _canvases.isNotEmpty &&
                _canvases.first.drawConfig.value.size != null
            ? _canvases.first.drawConfig.value.size!
            : Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height * 0.6,
              );

        if (decodedImages.isEmpty) return;

        for (int i = 0; i < decodedImages.length; i++) {
          final img = decodedImages[i];

          final double scaleW = baseSize.width / img.width;
          final double scaleH = baseSize.height / img.height;
          final double scale = scaleW < scaleH ? scaleW : scaleH;

          double fittedW = img.width * scale;
          double fittedH = img.height * scale;
          double offsetX = (baseSize.width - fittedW) / 2;
          double offsetY = (baseSize.height - fittedH) / 2;

          final content = ImageContent.data(
            image: img,
            imageUrl: result[i],
            startPoint: Offset(offsetX, offsetY),
            size: Offset(fittedW, fittedH),
            paint: Paint(),
          );

          final videoLayer = LayerData(
            id: 'video_layer_${DateTime.now().microsecondsSinceEpoch}_$i',
            name: 'Video Frame',
            history: [content],
            currentIndex: 1,
            isLocked: true,
          );

          if (i < _canvases.length) {
            // Video goes underneath existing drawings
            final canvasCtrl = _canvases[i];
            canvasCtrl.layers.add(videoLayer);

            // Retain original baseSize (fullscreen) to display canvas normally
            canvasCtrl.drawConfig.value = canvasCtrl.drawConfig.value.copyWith(
              size: baseSize,
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              canvasCtrl.forceRefreshLayers();
              canvasCtrl.updateSnapshot(includeBackground: false);
            });
          } else {
            final newController = DrawingController();
            newController.backgroundColor = Colors.white;

            // Constrain new canvas bounds strictly to preventing overlapping into application space
            newController.drawConfig.value = newController.drawConfig.value
                .copyWith(size: baseSize);

            newController.drawConfig.addListener(_onDrawConfigChanged);
            newController.interceptDraw = _createInterceptDraw(newController);

            newController.realTimeSnapshot.addListener(() {
              if (!mounted) return;
              final idx = _canvases.indexOf(newController);
              if (idx != -1) {
                setState(() {
                  _thumbnails[idx] = newController.realTimeSnapshot.value;
                });
              }
            });

            // Insert video at the very bottom (under the default drawing layer)
            newController.layers.add(videoLayer);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              newController.forceRefreshLayers();
              newController.updateSnapshot(includeBackground: false);
            });

            setState(() {
              _canvases.add(newController);
              _thumbnails.add(null);
            });
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      } catch (e) {
        debugPrint('Error inserting frames: $e');
      } finally {
        if (mounted) {
          Navigator.pop(context);
          _updateSnapshot();
        }
      }
    }
  }

  Future<void> _openGallery() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final List<ui.Image> capturedImages = [];

      for (int i = 0; i < _canvases.length; i++) {
        final controller = _canvases[i];

        // Use a temporary additionalDraw to capture the specific active sticker if it's the current one
        // or just capture the drawing state.
        final img = await controller.captureFullImage(
          backgroundColor: _globalBackground.color,
          backgroundImage: _globalBackground.image,
          backgroundImageOpacity: _globalBackground.imageOpacity,
          additionalDraw: (canvas, size) {
            // If we are capturing the currently active canvas, we might want to include the active sticker
            if (i == _currentIndex && _activeSticker != null) {
              if (_activeSticker is ActiveShapeSticker) {
                final sticker = _activeSticker as ActiveShapeSticker;
                canvas.save();
                canvas.translate(sticker.offset.dx, sticker.offset.dy);
                canvas.rotate(sticker.rotation);
                canvas.scale(sticker.scale);
                canvas.translate(
                  -sticker.size.width / 2,
                  -sticker.size.height / 2,
                );
                sticker.content.draw(canvas, sticker.size, false);
                canvas.restore();
              } else if (_activeSticker is ActiveFreehandLineSticker) {
                final sticker = _activeSticker as ActiveFreehandLineSticker;
                sticker.content.draw(canvas, Size.zero, false);
              } else if (_activeSticker is ActiveStraightLineSticker) {
                final line = _activeSticker as ActiveStraightLineSticker;
                canvas.drawLine(line.startPoint, line.endPoint, line.paint);
              } else if (_activeSticker is ActiveTextSticker) {
                final textSticker = _activeSticker as ActiveTextSticker;
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: textSticker.text,
                    style: TextStyle(
                      color: textSticker.color,
                      fontSize: textSticker.fontSize,
                      fontWeight: textSticker.isBold
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontFamily: textSticker.fontFamily,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();

                canvas.save();
                canvas.translate(textSticker.offset.dx, textSticker.offset.dy);
                canvas.rotate(textSticker.rotation);
                canvas.scale(textSticker.scale);
                canvas.translate(
                  -textPainter.width / 2,
                  -textPainter.height / 2,
                );
                textPainter.paint(canvas, Offset.zero);
                canvas.restore();
              }
            }
          },
        );

        if (img != null) {
          capturedImages.add(img);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GalleryScreen(images: capturedImages),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to capture images: $e')));
    }
  }

  bool Function(PaintContent) _createInterceptDraw(
    DrawingController controller,
  ) {
    return (content) {
      if (controller.isCurrentLayerLocked) return false;
      if (content is Circle && content.radius > 0) {
        final double inflation = content.paint.strokeWidth / 2;
        final actualCenter = content.startFromCenter
            ? content.startPoint
            : content.center;

        Rect bounds;
        if (content.isEllipse) {
          bounds = Rect.fromPoints(
            content.startPoint,
            content.endPoint,
          ).inflate(inflation);
        } else {
          bounds = Rect.fromCircle(
            center: actualCenter,
            radius: content.radius,
          ).inflate(inflation);
        }

        final localContent = Circle.data(
          isEllipse: content.isEllipse,
          startFromCenter: content.startFromCenter,
          center: content.center - bounds.topLeft,
          radius: content.radius,
          startPoint: content.startPoint - bounds.topLeft,
          endPoint: content.endPoint - bounds.topLeft,
          paint: content.paint,
        );

        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: localContent,
            offset: bounds.center,
            size: bounds.size,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is Rectangle &&
          content.startPoint != null &&
          content.endPoint != null) {
        final double inflation = content.paint.strokeWidth / 2;
        final bounds = Rect.fromPoints(
          content.startPoint!,
          content.endPoint!,
        ).inflate(inflation);

        final localContent = Rectangle.data(
          startPoint: content.startPoint! - bounds.topLeft,
          endPoint: content.endPoint! - bounds.topLeft,
          paint: content.paint,
        );

        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: localContent,
            offset: bounds.center,
            size: bounds.size,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is FreehandLine) {
        if (content.points == null || content.points!.isEmpty) return false;

        setState(() {
          _activeSticker = ActiveFreehandLineSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: content,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is SimpleLine) {
        Offset start = content.startPoint ?? Offset.zero;
        Offset end = content.endPoint ?? Offset.zero;

        // "Tap to create" logic: if start and end are the same, create a default line
        if (start == end) {
          end = start + const Offset(100, 100);
        }

        setState(() {
          _activeSticker = ActiveStraightLineSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            startPoint: start,
            endPoint: end,
            paint: content.paint,
            type: 'SimpleLine',
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is Triangle) {
        final Triangle triangle = content;
        final path = triangle.getPath();
        final bounds = path.getBounds().inflate(triangle.paint.strokeWidth / 2);

        if (bounds.isEmpty) return false;

        final localContent = Triangle.data(
          startPoint: triangle.startPoint - bounds.topLeft,
          A: triangle.A - bounds.topLeft,
          B: triangle.B - bounds.topLeft,
          C: triangle.C - bounds.topLeft,
          paint: triangle.paint,
        );

        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: localContent,
            offset: bounds.center,
            size: bounds.size,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is ImageContent) {
        final ImageContent image = content;
        final bounds = Rect.fromPoints(
          image.startPoint,
          image.startPoint + image.size,
        ).inflate(image.paint.strokeWidth / 2);

        if (bounds.isEmpty) return false;

        final localContent = ImageContent.data(
          startPoint: image.startPoint - bounds.topLeft,
          size: image.size,
          image: image.image,
          imageUrl: image.imageUrl,
          paint: image.paint,
        );

        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: localContent,
            offset: bounds.center,
            size: bounds.size,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is StraightLine &&
          content.startPoint != null &&
          content.endPoint != null) {
        setState(() {
          _activeSticker = ActiveStraightLineSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            startPoint: content.startPoint!,
            endPoint: content.endPoint!,
            paint: content.paint,
            type: 'StraightLine',
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is Lasso) {
        final drawPath = content.getDrawPath();
        drawPath.path.close(); // explicitly close the finalized lasso path
        final bounds = drawPath.path.getBounds();

        if (bounds.isEmpty) return false;

        // 1. Create a hole punch effect on the canvas using our EraserHole
        final Paint eraserPaint = Paint()
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.clear;

        // Take history before adding hole punch
        final historyCopy = controller.getHistory
            .take(controller.currentIndex)
            .map((e) => e.copy())
            .toList();

        controller.addContent(EraserHole(path: drawPath, paint: eraserPaint));

        // 2. Spawn the new sticker representing the pixels inside the lasso
        final ClippedHistoryContent stickerContent = ClippedHistoryContent(
          historyCopy,
          drawPath,
          bounds,
        );

        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: stickerContent,
            offset: bounds.center,
            size: bounds.size,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is ShapeStickerContent) {
        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: content.child,
            offset: content.offset,
            size: content.size,
            scale: content.scale,
            rotation: content.rotation,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is GroupContent) {
        if (content.children.isEmpty) return false;

        final bounds = content.getPath().getBounds();
        if (bounds.isEmpty) return false;

        content.boundsOffset = -bounds.topLeft;

        setState(() {
          _activeSticker = ActiveShapeSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: content,
            offset: bounds.center,
            size: bounds.size,
          );
        });
        _updateSnapshot();
        return true;
      } else if (content is TextContent) {
        setState(() {
          _activeSticker = ActiveTextSticker(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: content.text,
            color: content.paint.color,
            fontSize: content.fontSize,
            offset: content.offset,
            scale: content.scale,
            rotation: content.rotation,
            fontFamily: content.fontFamily,
            isBold: content.isBold,
          );
        });
        _updateSnapshot();
        return true;
      }
      return false;
    };
  }

  void _stampActiveSticker() {
    if (_drawingController.isCurrentLayerLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Current layer is locked.')));
      return;
    }

    if (_activeSticker is ActiveTextSticker) {
      final sticker = _activeSticker as ActiveTextSticker;

      final Paint paint = _drawingController.drawConfig.value.paint.copyWith()
        ..color = sticker.color;

      final textContent = TextContent.data(
        offset: sticker.offset,
        text: sticker.text,
        scale: sticker.scale,
        rotation: sticker.rotation,
        fontSize: sticker.fontSize,
        isBold: sticker.isBold,
        fontFamily: sticker.fontFamily,
        paint: paint,
      );

      setState(() {
        _activeSticker = null;
      });
      _drawingController.addContent(textContent);
    } else if (_activeSticker is ActiveShapeSticker) {
      final sticker = _activeSticker as ActiveShapeSticker;

      final shapeContent = ShapeStickerContent.data(
        child: sticker.content,
        offset: sticker.offset,
        scale: sticker.scale,
        rotation: sticker.rotation,
        size: sticker.size,
        paint: sticker.content.paint,
      );

      setState(() {
        _activeSticker = null;
      });
      _drawingController.addContent(shapeContent);
    } else if (_activeSticker is ActiveStraightLineSticker) {
      final sticker = _activeSticker as ActiveStraightLineSticker;

      final PaintContent lineContent;
      if (sticker.type == 'SimpleLine') {
        lineContent = SimpleLine.data(
          startPoint: sticker.startPoint,
          endPoint: sticker.endPoint,
          paint: sticker.paint,
        );
      } else {
        lineContent = StraightLine.data(
          startPoint: sticker.startPoint,
          endPoint: sticker.endPoint,
          paint: sticker.paint,
        );
      }

      setState(() {
        _activeSticker = null;
      });
      _drawingController.addContent(lineContent);
    } else if (_activeSticker is ActiveFreehandLineSticker) {
      final sticker = _activeSticker as ActiveFreehandLineSticker;
      setState(() {
        _activeSticker = null;
      });
      _drawingController.addContent(sticker.content);
    }
  }

  void _addTextSticker() {
    if (_drawingController.isCurrentLayerLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Current layer is locked.')));
      return;
    }
    String text = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Text Sticker'),
          content: TextField(
            onChanged: (v) => text = v,
            decoration: const InputDecoration(hintText: 'Enter text here'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (text.isNotEmpty) {
                  setState(() {
                    _activeSticker = ActiveTextSticker(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      text: text,
                      color: _drawingController.drawConfig.value.color,
                      fontSize: 24,
                    );
                  });
                  _updateSnapshot();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _pasteClipboard() {
    if (_drawingController.isCurrentLayerLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Current layer is locked.')));
      return;
    }
    final PaintContent? pasted = _drawingController.getPastedContent();
    if (pasted != null) {
      if (pasted is ShapeStickerContent) {
        pasted.offset += const Offset(20, 20);
      } else if (pasted is TextContent) {
        pasted.offset += const Offset(20, 20);
      }
      bool intercepted = false;
      if (_drawingController.interceptDraw != null) {
        intercepted = _drawingController.interceptDraw!(pasted);
      }
      if (!intercepted) {
        _drawingController.addContent(pasted);
        _updateSnapshot(); // Add this line
      }
    }
  }

  /// 获取画板数据 `getImageData()`
  Future<void> _getImageData() async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer
        .asUint8List();
    if (data == null) {
      debugPrint('获取图片数据失败');
      return;
    }

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (BuildContext c) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(c),
              child: Image.memory(data),
            ),
          );
        },
      );
    }
  }

  /// 获取画板内容 Json `getJsonList()`
  Future<void> _getJson() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        return Center(
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => Navigator.pop(c),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 800,
                ),
                padding: const EdgeInsets.all(20.0),
                child: SelectableText(
                  const JsonEncoder.withIndent(
                    '  ',
                  ).convert(_drawingController.getJsonList()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadBackgroundImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _globalBackground = _globalBackground.copyWith(
          image: frame.image,
          imagePath: path,
        );
      });
      _updateSnapshot();
    } catch (e) {
      debugPrint('Failed to load background image: $e');
    }
  }

  void _openPreviewScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimationPreviewScreen(
          canvases: _canvases,
          aspectRatio: _aspectRatio,
          globalBackground: _globalBackground,
          initialFps: _fps,
        ),
      ),
    ).then((result) {
      if (result != null && result is int) {
        setState(() {
          _fps = result;
        });
        _saveProject(); // Auto-save project settings (like FPS) when returning
      }
    });
  }

  void _showBackgroundSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Background Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        Colors.white,
                        Colors.lime[100]!,
                        Colors.blue[50]!,
                        Colors.pink[50]!,
                        Colors.grey[200]!,
                        Colors.amber[50]!,
                      ].map((color) {
                        final isSelected = _globalBackground.color == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _globalBackground = _globalBackground.copyWith(
                                color: color,
                              );
                            });
                            _updateSnapshot();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.pinkAccent
                                    : Colors.black12,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Colors.pinkAccent,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Background Image',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _backgroundActionButton(
                      label: 'Gallery',
                      icon: Icons.photo_library,
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          _loadBackgroundImage(image.path);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _backgroundActionButton(
                      label: 'Camera',
                      icon: Icons.camera_alt,
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (image != null) {
                          _loadBackgroundImage(image.path);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _backgroundActionButton(
                      label: 'Clear Image',
                      icon: Icons.layers_clear_rounded,
                      onTap: () {
                        setState(() {
                          _globalBackground = _globalBackground.copyWith(
                            clearImage: true,
                          );
                        });
                        _updateSnapshot();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _backgroundActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _restBoard() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _saveCanvasData() async {
    if (_activeSticker != null) {
      _stampActiveSticker();
    }
    final List<Map<String, dynamic>> jsonList = await _drawingController
        .getJsonList();
    setState(() {
      _savedJsonData = jsonEncode(jsonList);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Canvas data saved successfully!')),
    );
  }

  Future<void> _rehydrateContent(
    PaintContent content,
    Map<String, dynamic> data,
  ) async {
    if (content is BlurContent ||
        content is SmudgeContent ||
        content is FillContent) {
      final String? base64Data = data['imageDataBase64'] as String?;
      if (base64Data != null && base64Data.isNotEmpty) {
        try {
          final Uint8List bytes = base64Decode(base64Data);
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image decodedImage = frameInfo.image;

          if (content is BlurContent) {
            content.image = decodedImage;
          } else if (content is SmudgeContent) {
            content.image = decodedImage;
          } else if (content is FillContent) {
            content.image = decodedImage;
          }
        } catch (e) {
          debugPrint('Failed to rehydrate ${content.contentType}: $e');
        }
      }
    } else if (content is ImageContent) {
      if (content.image == null) {
        final String? imageUrl = data['imageUrl'] as String?;
        if (imageUrl != null) {
          try {
            if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
              content.image = await _getImage(imageUrl);
            } else {
              content.image = await _getFileImage(imageUrl);
            }
          } catch (e) {
            debugPrint('Failed to rehydrate ImageContent: $e');
          }
        }
      }
    } else if (content is GroupContent) {
      final List<dynamic> childrenData =
          data['children'] as List<dynamic>? ?? [];
      for (
        int i = 0;
        i < content.children.length && i < childrenData.length;
        i++
      ) {
        await _rehydrateContent(
          content.children[i],
          childrenData[i] as Map<String, dynamic>,
        );
      }
    } else if (content is ClippedHistoryContent) {
      final List<dynamic> historyData = data['history'] as List<dynamic>? ?? [];
      for (
        int i = 0;
        i < content.history.length && i < historyData.length;
        i++
      ) {
        await _rehydrateContent(
          content.history[i],
          historyData[i] as Map<String, dynamic>,
        );
      }
    } else if (content is ShapeStickerContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContent(content.child, childData);
      }
    } else if (content is OffsetContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContent(content.child, childData);
      }
    } else if (content is ClippedContent) {
      final Map<String, dynamic>? childData =
          data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContent(content.child, childData);
      }
    }
  }

  Future<void> _loadCanvasData() async {
    if (_savedJsonData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No saved data found.')));
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(_savedJsonData!);
      final List<PaintContent> contents = [];

      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final String type = item['type'] as String;

          final PaintContent? content = decodePaintContent(type, item);
          if (content != null) {
            await _rehydrateContent(content, item);
            contents.add(content);
          } else {
            debugPrint('Unknown PaintContent type in JSON: $type');
          }
        }
      }

      setState(() {
        _activeSticker = null;
      });
      _drawingController.clear();
      _drawingController.addContents(contents);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canvas data restored successfully!')),
      );
    } catch (e) {
      debugPrint('Failed to restore canvas data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to restore canvas data.')),
      );
    }
  }

  Future<void> _showAspectRatioDialog() async {
    final double? selectedRatio = await showDialog<double?>(
      context: context,
      barrierDismissible: false, // Force selection
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent physical back button evasion
          child: AlertDialog(
            title: const Text('Select Canvas Aspect Ratio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Free (Fill Space)'),
                    onTap: () => Navigator.pop(context, null),
                  ),
                  ListTile(
                    title: const Text('1:1 Square'),
                    onTap: () => Navigator.pop(context, 1.0),
                  ),
                  ListTile(
                    title: const Text('4:3'),
                    onTap: () => Navigator.pop(context, 4 / 3),
                  ),
                  ListTile(
                    title: const Text('16:9 Wide'),
                    onTap: () => Navigator.pop(context, 16 / 9),
                  ),
                  ListTile(
                    title: const Text('9:16 Portrait'),
                    onTap: () => Navigator.pop(context, 9 / 16),
                  ),
                  ListTile(
                    title: const Text('3:4 Portrait'),
                    onTap: () => Navigator.pop(context, 3 / 4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    setState(() {
      _aspectRatio = selectedRatio;
    });

    // Clear cached drawing board boundaries so layout sizes explicitly to new constraints
    for (var controller in _canvases) {
      controller.clearBoardSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProject) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey,
      appBar: AppBar(
        leading: PopupMenuButton<Color>(
          icon: const Icon(Icons.color_lens),
          onSelected: (ui.Color value) => _drawingController.setStyle(
            color: value.withValues(alpha: _colorOpacity),
          ),
          itemBuilder: (_) {
            return <PopupMenuEntry<ui.Color>>[
              PopupMenuItem<Color>(
                child: StatefulBuilder(
                  builder:
                      (
                        BuildContext context,
                        Function(void Function()) setState,
                      ) {
                        return Slider(
                          value: _colorOpacity,
                          onChanged: (double v) {
                            setState(() => _colorOpacity = v);
                            _drawingController.setStyle(
                              color: _drawingController.drawConfig.value.color
                                  .withValues(alpha: _colorOpacity),
                            );
                          },
                        );
                      },
                ),
              ),
              ...Colors.accents.map((ui.Color color) {
                return PopupMenuItem<ui.Color>(
                  value: color,
                  child: Container(width: 100, height: 50, color: color),
                );
              }),
            ];
          },
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Play Preview',
                onPressed: _openPreviewScreen,
              ),
              IconButton(
                icon: const Icon(Icons.wallpaper),
                tooltip: 'Background',
                onPressed: _showBackgroundSettings,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save JSON',
                onPressed: _saveCanvasData,
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Load JSON',
                onPressed: _loadCanvasData,
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'clear',
                onPressed: () {
                  if (_drawingController.isCurrentLayerLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Current layer is locked.'),
                      ),
                    );
                    return;
                  }
                  _drawingController.clear();
                },
              ),
              IconButton(
                icon: const Icon(Icons.text_fields),
                onPressed: _addTextSticker,
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _getImageData,
              ),
              IconButton(
                tooltip: 'Paste',
                icon: const Icon(Icons.paste),
                onPressed: () {
                  if (_activeSticker != null) {
                    _stampActiveSticker();
                  }
                  _pasteClipboard();
                },
              ),
              IconButton(
                icon: const Icon(Icons.restore_page_rounded),
                onPressed: _restBoard,
              ),
            ],
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: const [],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(systemNavigationBarColor: Colors.grey),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        Widget buildBoard(BoxConstraints c) {
                          return Stack(
                            children: [
                              DrawingBoard(
                                transformationController:
                                    _transformationController,
                                controller: _drawingController,
                                onPointerDown: (e) {
                                  if (_drawingController.isCurrentLayerLocked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Current layer is locked.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (_activeSticker != null) {
                                    _stampActiveSticker();
                                  }
                                },
                                boardPanEnabled:
                                    _activeSticker == null &&
                                    !_drawingController.isCurrentLayerLocked,
                                boardScaleEnabled:
                                    _activeSticker == null &&
                                    !_drawingController.isCurrentLayerLocked,
                                isDrawingEnabled:
                                    _activeSticker == null &&
                                    !_drawingController.isCurrentLayerLocked,
                                background: ValueListenableBuilder<DrawConfig>(
                                  valueListenable:
                                      _drawingController.drawConfig,
                                  builder: (context, config, child) {
                                    return Container(
                                      width: config.size?.width ?? c.maxWidth,
                                      height:
                                          config.size?.height ?? c.maxHeight,
                                      color: _globalBackground.color,
                                      child: Stack(
                                        children: [
                                          if (_globalBackground.image != null)
                                            Positioned.fill(
                                              child: Opacity(
                                                opacity: _globalBackground
                                                    .imageOpacity,
                                                child: RawImage(
                                                  image:
                                                      _globalBackground.image,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          if (_globalBackground.pattern !=
                                                  null &&
                                              _globalBackground.pattern !=
                                                  'none')
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: PatternPainter(
                                                  _globalBackground.pattern!,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                foreground: _activeSticker == null
                                    ? null
                                    : Stack(
                                        fit: StackFit.expand,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned.fill(
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                _stampActiveSticker();
                                              },
                                            ),
                                          ),
                                          if (_activeSticker
                                              is ActiveTextSticker)
                                            TextStickerWidget(
                                              key: ValueKey(
                                                (_activeSticker
                                                        as ActiveTextSticker)
                                                    .id,
                                              ),
                                              data:
                                                  _activeSticker
                                                      as ActiveTextSticker,
                                              onUpdate: (offset, scale, rotation) {
                                                (_activeSticker
                                                            as ActiveTextSticker)
                                                        .offset =
                                                    offset;
                                                (_activeSticker
                                                            as ActiveTextSticker)
                                                        .scale =
                                                    scale;
                                                (_activeSticker
                                                            as ActiveTextSticker)
                                                        .rotation =
                                                    rotation;
                                              },
                                              onUpdateEnd:
                                                  _recordActiveStickerState,
                                              onDelete: () {
                                                setState(() {
                                                  _activeSticker = null;
                                                });
                                                _updateSnapshot();
                                              },
                                              onConfirm: () {
                                                _stampActiveSticker();
                                              },
                                            ),
                                          if (_activeSticker
                                              is ActiveTextSticker)
                                            Positioned(
                                              top:
                                                  MediaQuery.of(
                                                    context,
                                                  ).padding.top +
                                                  20,
                                              left: 20,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    DropdownButton<String>(
                                                      value:
                                                          (_activeSticker
                                                                  as ActiveTextSticker)
                                                              .fontFamily,
                                                      hint: const Text('Font'),
                                                      items:
                                                          <String>[
                                                            'Roboto',
                                                            'Arial',
                                                            'Courier New',
                                                            'Times New Roman',
                                                            'Verdana',
                                                            'Georgia',
                                                          ].map((String value) {
                                                            return DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: value,
                                                              child: Text(
                                                                value,
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      value,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                      onChanged: (String? newValue) {
                                                        setState(() {
                                                          (_activeSticker
                                                                      as ActiveTextSticker)
                                                                  .fontFamily =
                                                              newValue;
                                                        });
                                                        _updateSnapshot();
                                                        _recordActiveStickerState();
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.format_bold,
                                                        color:
                                                            (_activeSticker
                                                                    as ActiveTextSticker)
                                                                .isBold
                                                            ? Colors.blue
                                                            : Colors.black,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          (_activeSticker
                                                                      as ActiveTextSticker)
                                                                  .isBold =
                                                              !(_activeSticker
                                                                      as ActiveTextSticker)
                                                                  .isBold;
                                                        });
                                                        _updateSnapshot();
                                                        _recordActiveStickerState();
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.text_increase,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          (_activeSticker
                                                                      as ActiveTextSticker)
                                                                  .fontSize +=
                                                              2;
                                                        });
                                                        _updateSnapshot();
                                                        _recordActiveStickerState();
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.text_decrease,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          (_activeSticker
                                                                      as ActiveTextSticker)
                                                                  .fontSize =
                                                              ((_activeSticker
                                                                              as ActiveTextSticker)
                                                                          .fontSize -
                                                                      2)
                                                                  .clamp(
                                                                    8.0,
                                                                    120.0,
                                                                  );
                                                        });
                                                        _updateSnapshot();
                                                        _recordActiveStickerState();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (_activeSticker
                                              is ActiveFreehandLineSticker)
                                            FreehandLineStickerWidget(
                                              key: ValueKey(
                                                (_activeSticker
                                                        as ActiveFreehandLineSticker)
                                                    .id,
                                              ),
                                              data:
                                                  _activeSticker
                                                      as ActiveFreehandLineSticker,
                                              onSnap: (raw, anchor) {
                                                if (_showRulerMenu &&
                                                    _drawingController
                                                            .rulerConfig
                                                            .value
                                                            .type !=
                                                        RulerType.none) {
                                                  return _drawingController
                                                      .rulerConfig
                                                      .value
                                                      .projectPoint(
                                                        raw,
                                                        anchor,
                                                      );
                                                }
                                                return raw;
                                              },
                                              onUpdate: () {},
                                              onUpdateEnd:
                                                  _recordActiveStickerState,
                                              onDelete: () {
                                                setState(() {
                                                  _activeSticker = null;
                                                });
                                                _updateSnapshot();
                                              },
                                              onConfirm: () {
                                                _stampActiveSticker();
                                              },
                                            ),
                                          if (_activeSticker
                                              is ActiveShapeSticker)
                                            ShapeStickerWidget(
                                              key: ValueKey(
                                                (_activeSticker
                                                        as ActiveShapeSticker)
                                                    .id,
                                              ),
                                              data:
                                                  _activeSticker
                                                      as ActiveShapeSticker,
                                              onUpdate: (offset, scale, rotation) {
                                                (_activeSticker
                                                            as ActiveShapeSticker)
                                                        .offset =
                                                    offset;
                                                (_activeSticker
                                                            as ActiveShapeSticker)
                                                        .scale =
                                                    scale;
                                                (_activeSticker
                                                            as ActiveShapeSticker)
                                                        .rotation =
                                                    rotation;
                                              },
                                              onUpdateEnd:
                                                  _recordActiveStickerState,
                                              onDelete: () {
                                                setState(() {
                                                  _activeSticker = null;
                                                });
                                                _updateSnapshot();
                                              },
                                              onConfirm: () {
                                                _stampActiveSticker();
                                              },
                                            ),
                                          if (_activeSticker
                                              is ActiveStraightLineSticker)
                                            StraightLineStickerWidget(
                                              key: ValueKey(
                                                (_activeSticker
                                                        as ActiveStraightLineSticker)
                                                    .id,
                                              ),
                                              data:
                                                  _activeSticker
                                                      as ActiveStraightLineSticker,
                                              onSnap: (raw, anchor) {
                                                if (_showRulerMenu &&
                                                    _drawingController
                                                            .rulerConfig
                                                            .value
                                                            .type !=
                                                        RulerType.none) {
                                                  return _drawingController
                                                      .rulerConfig
                                                      .value
                                                      .projectPoint(
                                                        raw,
                                                        anchor,
                                                      );
                                                }
                                                return raw;
                                              },
                                              onUpdate: (start, end) {
                                                (_activeSticker
                                                            as ActiveStraightLineSticker)
                                                        .startPoint =
                                                    start;
                                                (_activeSticker
                                                            as ActiveStraightLineSticker)
                                                        .endPoint =
                                                    end;
                                              },
                                              onUpdateEnd:
                                                  _recordActiveStickerState,
                                              onDelete: () {
                                                setState(() {
                                                  _activeSticker = null;
                                                });
                                                _updateSnapshot();
                                              },
                                              onConfirm: () {
                                                _stampActiveSticker();
                                              },
                                            ),
                                        ],
                                      ),
                              ),
                              // Positioned(
                              //   left: 10,
                              //   bottom: 10,
                              //   child: DrawingPreview(
                              //     controller: _drawingController,
                              //     activeSticker: _activeSticker,
                              //     width: 100,
                              //     height: 100,
                              //   ),
                              // ),
                              if (_showRulerMenu &&
                                  (_drawingController
                                              .drawConfig
                                              .value
                                              .contentType ==
                                          FreehandLine ||
                                      _drawingController
                                              .drawConfig
                                              .value
                                              .contentType ==
                                          SmoothLine))
                                Positioned(
                                  bottom: 20,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: _buildFloatingRulerMenu(),
                                  ),
                                ),
                              Positioned(
                                right: 16,
                                top:
                                    40, // Place it right floating as shown in screenshot
                                child: _buildFloatingRightToolbar(),
                              ),
                              if (_showLayerPanel)
                                Positioned(
                                  right: 16,
                                  bottom: 80,
                                  child: LayerPanel(
                                    controller: _drawingController,
                                    onClose: () {
                                      setState(() {
                                        _showLayerPanel = false;
                                      });
                                    },
                                  ),
                                ),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton(
                                  mini: true,
                                  onPressed: () {
                                    setState(() {
                                      _showLayerPanel = !_showLayerPanel;
                                      _showRulerMenu = false;
                                    });
                                  },
                                  backgroundColor: _showLayerPanel
                                      ? Colors.pink
                                      : Colors.white,
                                  foregroundColor: _showLayerPanel
                                      ? Colors.white
                                      : Colors.black87,
                                  child: const Icon(Icons.layers),
                                ),
                              ),
                            ],
                          );
                        }

                        if (_aspectRatio != null) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: _aspectRatio!,
                              child: LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints aspectConstraints,
                                    ) {
                                      return buildBoard(aspectConstraints);
                                    },
                              ),
                            ),
                          );
                        } else {
                          return buildBoard(constraints);
                        }
                      },
                    ),
                  ),
                  // if (_showRulerMenu) _buildRulerMenu(),
                  DrawingBar(
                    controller: _drawingController,
                    style: const WrapToolsBarStyle(),
                    tools: [
                      DefaultActionItem.slider(),
                      DefaultActionItem.undo(),
                      DefaultActionItem.redo(),
                      DefaultActionItem.turn(),
                      DefaultActionItem.clear(),
                    ],
                  ),
                  DrawingBar(
                    controller: _drawingController,
                    style: const WrapToolsBarStyle(),
                    tools: [
                      DefaultToolItem.straightLine(), // This is the new 2-point SimpleLine
                      DefaultToolItem.pen(), // This is the freehand Pen
                      DefaultToolItem.rectangle(),
                      DefaultToolItem.circle(),
                      DefaultToolItem.text(context: context),
                      DefaultToolItem(
                        onTap: (c) async {
                          if (_drawingController.isCurrentLayerLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Current layer is locked.'),
                              ),
                            );
                            return;
                          }

                          // Show bottom sheet to choose Camera or Gallery
                          final ImageSource?
                          source = await showModalBottomSheet<ImageSource>(
                            context: context,
                            builder: (BuildContext context) {
                              return SafeArea(
                                child: Wrap(
                                  children: <Widget>[
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Photo Gallery'),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(ImageSource.gallery),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_camera),
                                      title: const Text('Camera'),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(ImageSource.camera),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );

                          if (source == null) return;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext c) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );

                          try {
                            final XFile? file = await _picker.pickImage(
                              source: source,
                            );
                            if (file != null) {
                              final ui.Image image = await _getFileImage(
                                file.path,
                              );
                              c.setPaintContent(
                                ImageContent(image, imageUrl: file.path),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error picking sticker image: $e');
                          } finally {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: Icons.image,
                        content: ImageContent,
                        label: 'Photo',
                      ),
                      DefaultToolItem(
                        onTap: (c) => c.setPaintContent(Triangle()),
                        icon: Icons.change_history_rounded,
                        content: Triangle,
                      ),
                      DefaultToolItem.lasso(),
                      DefaultToolItem.fill(),
                      DefaultToolItem.eyedropper(),
                      DefaultToolItem.blur(),
                      DefaultToolItem.smudge(),
                      DefaultToolItem.eraser(),
                      // Ruler button has been moved to floating menu
                    ],
                  ),
                  const SizedBox(
                    height: 120,
                  ), // Reserve space for CanvasSelector
                ],
              ),

              // Canvas Selector at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CanvasSelector(
                  thumbnails: _thumbnails,
                  currentIndex: _currentIndex,
                  onSelect: _selectCanvas,
                  onAdd: _addNewCanvas,
                  onOpenGallery: _openGallery,
                  onOpenFrames: _openFramesScreen,
                  onImportVideo: _importVideo,
                  onFrameAction: _onFrameAction,
                  canvasKeys: _canvases.map((c) => ObjectKey(c)).toList(),
                  onReorder: _reorderCanvas,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RulerToolItem extends StatelessWidget {
  const RulerToolItem({super.key, required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.straighten,
            size: 24,
            color: isActive ? Colors.pink : Colors.grey,
          ),
          const Text(
            'Ruler',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  final String pattern;
  const PatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    if (pattern == 'grid') {
      const double spacing = 20.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == 'dots') {
      const double spacing = 20.0;
      final dotPaint = Paint()..color = Colors.black.withOpacity(0.15);
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    } else if (pattern == 'lines') {
      const double spacing = 24.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      // Draw left vertical margin line in red
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        const Offset(40, 0),
        Offset(40, size.height),
        marginPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern;
}
