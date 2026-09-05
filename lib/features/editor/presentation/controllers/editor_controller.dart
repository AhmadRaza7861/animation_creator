import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../package_code/src/paint_extension/ex_paint.dart';
import '../../../../package_code/paint_contents.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/paint_contents/layer_data.dart';
import '../../../../package_code/src/paint_contents/paint_content_decoder.dart';
import '../../../../package_code/src/paint_contents/simple_line.dart';
import '../../../../package_code/src/paint_contents/smooth_line.dart';
import '../../../projects/data/project_repository.dart';
import '../widgets/sticker_widgets/text_sticker_widget.dart';
import '../widgets/sticker_widgets/shape_sticker_widget.dart';
import '../widgets/sticker_widgets/straight_line_sticker_widget.dart';
import '../widgets/sticker_widgets/freehand_line_sticker_widget.dart';

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

class EditorController extends ChangeNotifier {
  final ProjectRepository repository;
  final String? projectId;

  EditorController({
    required this.repository,
    this.projectId,
  }) {
    _addNewCanvas(initial: true);
    if (projectId != null) {
      loadProjectData();
    }
  }

  final List<DrawingController> _canvases = [];
  final List<ui.Image?> _thumbnails = [];
  CanvasBackground _globalBackground = CanvasBackground();
  int _currentIndex = 0;
  bool _isLoadingProject = false;
  
  double? _aspectRatio;
  String? _templateFolder;
  String? _templateExtension;
  String? _templateMode;
  int? _templateFrameCount;
  List<String> _templateFrameAssets = [];
  int _fps = 9;
  String? _savedJsonData;
  bool _enableStickers = true;

  // Onion skin settings
  bool _isOnionEnabled = true;
  bool _onionColorMode = false;
  bool _onionLoop = false;
  int _onionBefore = 1;
  int _onionAfter = 0;

  // Grid settings
  bool _isGridEnabled = false;
  double _gridOpacity = 0.25;
  double _gridVerticalSpacing = 80.0;
  double _gridHorizontalSpacing = 80.0;

  // UI state properties
  bool _isTextToolSelected = false;
  String _currentSubMenu = 'none';
  String _selectedSubTool = 'pen';
  String _selectedShape = 'heart';
  bool _showRulerMenu = false;
  bool _showLayerPanel = false;
  Offset? _layersPanelPosition;

  // Active Sticker placement state
  Object? _activeSticker;
  List<Object> _activeStickerHistory = [];
  int _activeStickerHistoryIndex = -1;

  Object? _undoneSticker;
  List<Object> _undoneStickerHistory = [];
  int _undoneStickerHistoryIndex = -1;

  bool _isUndoingActiveStickerPlacement = false;
  double _globalStrokeWidth = 4.0;
  String _activeCategory = 'Brush';
  double _colorOpacity = 1.0;

  // Getters
  List<DrawingController> get canvases => _canvases;
  List<ui.Image?> get thumbnails => _thumbnails;
  CanvasBackground get globalBackground => _globalBackground;
  int get currentIndex => _currentIndex;
  DrawingController get drawingController {
    if (_canvases.isEmpty) {
      _addNewCanvas(initial: true);
    }
    final int safeIndex = _currentIndex.clamp(0, _canvases.length - 1);
    return _canvases[safeIndex];
  }
  bool get isLoadingProject => _isLoadingProject;

  double? get aspectRatio => _aspectRatio;
  String? get templateFolder => _templateFolder;
  String? get templateExtension => _templateExtension;
  String? get templateMode => _templateMode;
  int? get templateFrameCount => _templateFrameCount;
  List<String> get templateFrameAssets => _templateFrameAssets;
  int get fps => _fps;
  bool get enableStickers => _enableStickers;

  bool get isOnionEnabled => _isOnionEnabled;
  bool get onionColorMode => _onionColorMode;
  bool get onionLoop => _onionLoop;
  int get onionBefore => _onionBefore;
  int get onionAfter => _onionAfter;

  bool get isGridEnabled => _isGridEnabled;
  double get gridOpacity => _gridOpacity;
  double get gridVerticalSpacing => _gridVerticalSpacing;
  double get gridHorizontalSpacing => _gridHorizontalSpacing;

  bool get isTextToolSelected => _isTextToolSelected;
  String get currentSubMenu => _currentSubMenu;
  String get selectedSubTool => _selectedSubTool;
  String get selectedShape => _selectedShape;
  bool get showRulerMenu => _showRulerMenu;
  bool get showLayerPanel => _showLayerPanel;
  Offset? get layersPanelPosition => _layersPanelPosition;

  Object? get activeSticker => _activeSticker;
  double get globalStrokeWidth => _globalStrokeWidth;
  String get activeCategory => _activeCategory;
  double get colorOpacity => _colorOpacity;

  set colorOpacity(double val) {
    _colorOpacity = val;
    notifyListeners();
  }

  set isTextToolSelected(bool val) {
    _isTextToolSelected = val;
    notifyListeners();
  }

  set currentSubMenu(String val) {
    _currentSubMenu = val;
    notifyListeners();
  }

  set selectedSubTool(String val) {
    _selectedSubTool = val;
    notifyListeners();
  }

  set selectedShape(String val) {
    _selectedShape = val;
    notifyListeners();
  }

  void selectShape(String shape) {
    if (_activeSticker != null) {
      stampActiveSticker();
    }
    _selectedShape = shape;
    switch (shape) {
      case 'line':
        drawingController.setPaintContent(SimpleLine());
        break;
      case 'circle':
        drawingController.setPaintContent(Circle());
        break;
      case 'square':
        drawingController.setPaintContent(Rectangle());
        break;
      case 'triangle':
        drawingController.setPaintContent(Triangle());
        break;
      case 'heart':
      default:
        drawingController.setPaintContent(Heart());
        break;
    }
    drawingController.setStyle(strokeWidth: _globalStrokeWidth);
    notifyListeners();
  }

  set showRulerMenu(bool val) {
    _showRulerMenu = val;
    notifyListeners();
  }

  set showLayerPanel(bool val) {
    _showLayerPanel = val;
    notifyListeners();
  }

  set layersPanelPosition(Offset? pos) {
    _layersPanelPosition = pos;
    notifyListeners();
  }

  set activeSticker(Object? value) {
    if (_activeSticker == value) return;
    _activeSticker = value;
    if (value == null) {
      _clearActiveStickerHistory();
    } else {
      _initActiveStickerHistory(value);
      _undoneSticker = null;
      _undoneStickerHistory.clear();
      _undoneStickerHistoryIndex = -1;
    }
    notifyListeners();
  }

  set activeCategory(String value) {
    if (_activeCategory != value && _activeSticker != null) {
      stampActiveSticker();
    }
    _activeCategory = value;
    notifyListeners();
  }

  set globalStrokeWidth(double val) {
    _globalStrokeWidth = val;
    notifyListeners();
  }

  set globalBackground(CanvasBackground bg) {
    _globalBackground = bg;
    notifyListeners();
  }

  set enableStickers(bool val) {
    _enableStickers = val;
    if (!val && _activeSticker != null) {
      stampActiveSticker();
    }
    notifyListeners();
  }

  set aspectRatio(double? ratio) {
    _aspectRatio = ratio;
    notifyListeners();
  }

  set fps(int value) {
    _fps = value;
    notifyListeners();
  }

  void updateGrid({bool? enabled, double? opacity, double? vertical, double? horizontal}) {
    if (enabled != null) _isGridEnabled = enabled;
    if (opacity != null) _gridOpacity = opacity;
    if (vertical != null) _gridVerticalSpacing = vertical;
    if (horizontal != null) _gridHorizontalSpacing = horizontal;
    notifyListeners();
  }

  void updateOnion({bool? enabled, bool? colorMode, bool? loop, int? before, int? after}) {
    if (enabled != null) _isOnionEnabled = enabled;
    if (colorMode != null) _onionColorMode = colorMode;
    if (loop != null) _onionLoop = loop;
    if (before != null) _onionBefore = before;
    if (after != null) _onionAfter = after;
    notifyListeners();
  }

  // Project hydration helpers
  Future<ui.Image> _getImage(String path) async {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    final NetworkImage img = NetworkImage(path);
    img.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener((ImageInfo info, _) {
        completer.complete(info);
      }),
    );
    final ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }

  Future<ui.Image> _getFileImage(String path) async {
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    final FileImage img = FileImage(File(path));
    img.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener((ImageInfo info, _) {
        completer.complete(info);
      }),
    );
    final ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }

  Future<ui.Image> _getAssetImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  void _onDrawConfigChanged() {
    final Size? activeSize = drawingController.drawConfig.value.size;
    if (activeSize != null && !activeSize.isEmpty) {
      bool propagated = false;
      for (var controller in _canvases) {
        if (controller.drawConfig.value.size != activeSize) {
          controller.drawConfig.removeListener(_onDrawConfigChanged);
          controller.drawConfig.value = controller.drawConfig.value.copyWith(size: activeSize);
          controller.drawConfig.addListener(_onDrawConfigChanged);
          propagated = true;
        }
      }

      for (int i = 0; i < _canvases.length; i++) {
        if (_thumbnails[i] == null) {
          _canvases[i].updateSnapshot(includeBackground: false);
        }
      }
      if (propagated) {
        notifyListeners();
      }
    }
  }

  Future<void> loadProjectData() async {
    if (projectId == null) return;
    _isLoadingProject = true;
    notifyListeners();

    final data = await repository.loadProject(projectId!);
    if (data != null && data.state['canvases'] != null) {
      if (data.state.containsKey('aspectRatio')) {
        _aspectRatio = data.state['aspectRatio'] as double?;
      }
      if (data.state.containsKey('fps')) {
        _fps = data.state['fps'] as int;
      }
      _templateFolder = data.state['templateFolder'] as String?;
      _templateExtension = data.state['templateExtension'] as String?;
      _templateMode = data.state['templateMode'] as String?;
      _templateFrameCount = data.state['templateFrameCount'] as int?;
      if (data.state.containsKey('templateFrameAssets')) {
        _templateFrameAssets = List<String>.from(data.state['templateFrameAssets'] as List);
      } else {
        _templateFrameAssets = [];
      }
      if (data.state.containsKey('enableStickers')) {
        _enableStickers = data.state['enableStickers'] as bool;
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
            final bytes = await File(_globalBackground.imagePath!).readAsBytes();
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
        _globalStrokeWidth = _canvases.first.drawConfig.value.strokeWidth;
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

    _isLoadingProject = false;
    notifyListeners();
  }

  Future<void> saveProject() async {
    if (_activeSticker != null) {
      stampActiveSticker();
    }
    if (_canvases.isEmpty || projectId == null) return;

    final Map<String, dynamic> state = {
      'globalBackground': {
        'color': _globalBackground.color.value,
        'imagePath': _globalBackground.imagePath,
        'imageOpacity': _globalBackground.imageOpacity,
        'pattern': _globalBackground.pattern,
      },
      'aspectRatio': _aspectRatio,
      'fps': _fps,
      'templateFolder': _templateFolder,
      'templateExtension': _templateExtension,
      'templateMode': _templateMode,
      'templateFrameCount': _templateFrameCount,
      'templateFrameAssets': _templateFrameAssets,
      'enableStickers': _enableStickers,
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
      final snapshotImg = _canvases.first.realTimeSnapshot.value;
      if (snapshotImg != null) {
        final byteData = await snapshotImg.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          thumbBytes = byteData.buffer.asUint8List();
        }
      }
    }

    await repository.saveProject(
      projectId: projectId,
      state: state,
      thumbnailBytes: thumbBytes,
    );
  }

  Future<DrawingController> _createControllerFromData(Map<String, dynamic> cMap) async {
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
      final matchedLayer = controller.layers.where((l) => l.id == activeLayerId).firstOrNull;
      if (matchedLayer != null) {
        controller.activeLayer.value = matchedLayer;
      } else {
        controller.activeLayer.value = controller.layers.first;
      }
    } else if (controller.layers.isNotEmpty) {
      controller.activeLayer.value = controller.layers.first;
    }

    controller.drawConfig.addListener(_onDrawConfigChanged);
    controller.interceptDraw = _createInterceptDraw(controller);
    controller.realTimeSnapshot.addListener(() {
      final idx = _canvases.indexOf(controller);
      if (idx != -1) {
        _thumbnails[idx] = controller.realTimeSnapshot.value;
        notifyListeners();
      }
    });

    return controller;
  }

  Future<void> _rehydrateContent(PaintContent content, Map<String, dynamic> data) async {
    if (content is BlurContent || content is SmudgeContent || content is FillContent) {
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
            } else if (imageUrl.startsWith('assets/')) {
              content.image = await _getAssetImage(imageUrl);
            } else {
              content.image = await _getFileImage(imageUrl);
            }
          } catch (e) {
            debugPrint('Failed to rehydrate ImageContent: $e');
          }
        }
      }
    } else if (content is GroupContent) {
      final List<dynamic> childrenData = data['children'] as List<dynamic>? ?? [];
      for (int i = 0; i < content.children.length && i < childrenData.length; i++) {
        await _rehydrateContent(content.children[i], childrenData[i] as Map<String, dynamic>);
      }
    } else if (content is ClippedHistoryContent) {
      final List<dynamic> historyData = data['history'] as List<dynamic>? ?? [];
      for (int i = 0; i < content.history.length && i < historyData.length; i++) {
        await _rehydrateContent(content.history[i], historyData[i] as Map<String, dynamic>);
      }
    } else if (content is ShapeStickerContent) {
      final Map<String, dynamic>? childData = data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContent(content.child, childData);
      }
    } else if (content is OffsetContent) {
      final Map<String, dynamic>? childData = data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContent(content.child, childData);
      }
    } else if (content is ClippedContent) {
      final Map<String, dynamic>? childData = data['child'] as Map<String, dynamic>?;
      if (childData != null) {
        await _rehydrateContent(content.child, childData);
      }
    }
  }

  void _addNewCanvas({bool initial = false, int? atIndex}) {
    final controller = DrawingController();
    controller.drawConfig.value = controller.drawConfig.value.copyWith(
      strokeWidth: _globalStrokeWidth,
      size: drawingControllerSize,
    );

    controller.drawConfig.addListener(_onDrawConfigChanged);
    controller.interceptDraw = _createInterceptDraw(controller);
    controller.realTimeSnapshot.addListener(() {
      final idx = _canvases.indexOf(controller);
      if (idx != -1) {
        _thumbnails[idx] = controller.realTimeSnapshot.value;
        notifyListeners();
      }
    });

    if (initial) {
      _canvases.add(controller);
      _thumbnails.add(null);
      _currentIndex = 0;
    } else {
      if (_activeSticker != null) {
        stampActiveSticker();
      }
      final targetIndex = atIndex ?? (_currentIndex + 1);
      _canvases.insert(targetIndex, controller);
      _thumbnails.insert(targetIndex, null);
      _currentIndex = targetIndex;
    }
    notifyListeners();
  }

  Size? get drawingControllerSize {
    if (_canvases.isNotEmpty) {
      return _canvases.first.drawConfig.value.size;
    }
    return null;
  }

  // Frame manipulation methods
  void selectCanvas(int index) {
    if (index >= 0 && index < _canvases.length) {
      if (_activeSticker != null) {
        stampActiveSticker();
      }
      _currentIndex = index;
      notifyListeners();
    }
  }

  void addFrame() {
    _addNewCanvas();
  }

  void addFrameAt(int index, {bool isRight = true}) {
    final targetIndex = isRight ? (index + 1) : index;
    _addNewCanvas(atIndex: targetIndex);
  }

  Future<void> importVideoFrames(List<String> framePaths) async {
    if (framePaths.isEmpty) return;
    if (_activeSticker != null) {
      stampActiveSticker();
    }

    final int targetStartIndex = _currentIndex.clamp(0, _canvases.isNotEmpty ? _canvases.length - 1 : 0);

    for (int i = 0; i < framePaths.length; i++) {
      final path = framePaths[i];
      try {
        final File file = File(path);
        if (!await file.exists()) continue;
        final Uint8List bytes = await file.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();
        final ui.Image image = fi.image;

        final imageContent = ImageContent(image, imageUrl: path);
        imageContent.startPoint = Offset.zero;
        imageContent.size = Offset.zero;

        final int frameIndex = targetStartIndex + i;

        if (frameIndex < _canvases.length) {
          // Existing frame: insert video frame underneath existing drawings
          final existingCanvas = _canvases[frameIndex];
          existingCanvas.insertContentAsBase(imageContent);
          _thumbnails[frameIndex] = image;
        } else {
          // Additional frame: append new canvas frame
          final newCanvas = DrawingController();
          newCanvas.drawConfig.value = newCanvas.drawConfig.value.copyWith(
            strokeWidth: _globalStrokeWidth,
            size: drawingControllerSize,
          );
          newCanvas.drawConfig.addListener(_onDrawConfigChanged);
          newCanvas.interceptDraw = _createInterceptDraw(newCanvas);
          newCanvas.realTimeSnapshot.addListener(() {
            final idx = _canvases.indexOf(newCanvas);
            if (idx != -1) {
              _thumbnails[idx] = newCanvas.realTimeSnapshot.value;
              notifyListeners();
            }
          });

          newCanvas.addContent(imageContent);
          _canvases.add(newCanvas);
          _thumbnails.add(image);
        }
      } catch (e) {
        debugPrint('Error importing video frame $path: $e');
      }
    }

    if (_canvases.isNotEmpty) {
      _currentIndex = targetStartIndex.clamp(0, _canvases.length - 1);
    }
    notifyListeners();
  }

  void deleteFrame(int index) {
    if (_canvases.length <= 1) return;
    if (_activeSticker != null) {
      if (index != _currentIndex) {
        stampActiveSticker();
      } else {
        _activeSticker = null;
        _clearActiveStickerHistory();
      }
    }
    final controller = _canvases.removeAt(index);
    controller.drawConfig.removeListener(_onDrawConfigChanged);
    controller.dispose();
    _thumbnails.removeAt(index);

    if (_currentIndex >= _canvases.length) {
      _currentIndex = _canvases.length - 1;
    }
    notifyListeners();
  }

  void reorderFrames(int oldIndex, int newIndex) {
    if (_activeSticker != null) {
      stampActiveSticker();
    }
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final controller = _canvases.removeAt(oldIndex);
    _canvases.insert(newIndex, controller);

    final thumb = _thumbnails.removeAt(oldIndex);
    _thumbnails.insert(newIndex, thumb);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
      _currentIndex -= 1;
    } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
      _currentIndex += 1;
    }
    notifyListeners();
  }

  void applyFramesOrder(List<int> order, int activeIndex) {
    if (_activeSticker != null) {
      stampActiveSticker();
    }
    if (order.length != _canvases.length) return;
    final List<DrawingController> newCanvases = [];
    final List<ui.Image?> newThumbs = [];
    for (final idx in order) {
      newCanvases.add(_canvases[idx]);
      newThumbs.add(_thumbnails[idx]);
    }
    _canvases.clear();
    _canvases.addAll(newCanvases);
    _thumbnails.clear();
    _thumbnails.addAll(newThumbs);
    _currentIndex = activeIndex.clamp(0, _canvases.length - 1);
    notifyListeners();
  }

  void duplicateFrame(int index) async {
    if (_activeSticker != null) {
      stampActiveSticker();
    }
    final source = _canvases[index];
    final duplicated = DrawingController();
    duplicated.backgroundColor = source.backgroundColor;
    duplicated.drawConfig.value = source.drawConfig.value;

    final layersJson = await source.getLayersConfig();
    duplicated.layers.clear();
    for (final lData in layersJson) {
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
      duplicated.layers.add(
        LayerData(
          id: 'layer_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(100)}',
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
    
    final activeId = source.activeLayer.value?.id;
    if (activeId != null && duplicated.layers.isNotEmpty) {
      duplicated.activeLayer.value = duplicated.layers.firstWhere((l) => l.name == source.activeLayer.value?.name, orElse: () => duplicated.layers.first);
    } else if (duplicated.layers.isNotEmpty) {
      duplicated.activeLayer.value = duplicated.layers.first;
    }

    duplicated.drawConfig.addListener(_onDrawConfigChanged);
    duplicated.interceptDraw = _createInterceptDraw(duplicated);
    duplicated.realTimeSnapshot.addListener(() {
      final idx = _canvases.indexOf(duplicated);
      if (idx != -1) {
        _thumbnails[idx] = duplicated.realTimeSnapshot.value;
        notifyListeners();
      }
    });

    _canvases.insert(index + 1, duplicated);
    _thumbnails.insert(index + 1, null);
    _currentIndex = index + 1;
    notifyListeners();
  }

  void copyFrame(int index) async {
    if (_activeSticker != null && index == _currentIndex) {
      stampActiveSticker();
    }
    final source = _canvases[index];
    final size = source.drawConfig.value.size ?? Size.zero;
    _clipboardFrame = {
      'size': {'width': size.width, 'height': size.height},
      'backgroundColor': source.backgroundColor.value,
      'layers': await source.getLayersConfig(),
      'activeLayerId': source.activeLayer.value?.id,
    };
  }

  Map<String, dynamic>? _clipboardFrame;
  bool get hasClipboardFrame => _clipboardFrame != null;

  void pasteFrame(int index) async {
    if (_clipboardFrame == null) return;
    if (index < 0 || index >= _canvases.length) return;
    if (_activeSticker != null) {
      stampActiveSticker();
    }

    final targetController = _canvases[index];
    final layersData = _clipboardFrame!['layers'] as List<dynamic>? ?? [];

    final List<LayerData> copiedLayers = [];
    for (final lData in layersData) {
      final lMap = lData as Map<String, dynamic>;
      final historyData = lMap['history'] as List<dynamic>? ?? [];
      final List<PaintContent> history = [];
      for (final hData in historyData) {
        final hMap = hData as Map<String, dynamic>;
        final content = decodePaintContent(hMap['type'] as String, hMap);
        if (content != null) {
          await _rehydrateContent(content, hMap);
          history.add(content);
        }
      }
      if (history.isNotEmpty) {
        copiedLayers.add(
          LayerData(
            id: 'layer_${DateTime.now().millisecondsSinceEpoch}_${copiedLayers.length}',
            name: lMap['name'] as String? ?? 'Pasted Layer',
            isVisible: lMap['isVisible'] as bool? ?? true,
            isLocked: false,
            opacity: (lMap['opacity'] as num?)?.toDouble() ?? 1.0,
            blendMode: BlendMode.values[(lMap['blendMode'] as int?) ?? 0],
            history: history,
            currentIndex: history.length,
          ),
        );
      }
    }

    if (copiedLayers.isEmpty) return;

    if (targetController.layers.isEmpty) {
      targetController.layers.add(LayerData(id: 'layer_0', name: 'Background'));
    }
    targetController.activeLayer.value ??= targetController.layers.first;

    final bool isTargetEmpty = targetController.layers.every((l) => l.history.isEmpty || l.currentIndex == 0);

    if (isTargetEmpty) {
      targetController.layers.clear();
      targetController.layers.addAll(copiedLayers);
      targetController.activeLayer.value = targetController.layers.first;
    } else {
      if (copiedLayers.length == 1) {
        targetController.activeLayer.value!.isLocked = false;
        targetController.addContents(copiedLayers.first.history);
      } else {
        for (final cl in copiedLayers.reversed) {
          targetController.layers.insert(0, cl);
        }
        targetController.activeLayer.value = targetController.layers.first;
      }
    }

    targetController.forceRefreshLayers();
    targetController.updateSnapshot(includeBackground: false);
    _currentIndex = index;
    notifyListeners();
  }

  void updateSnapshot() {
    drawingController.updateSnapshot(includeBackground: false);
  }

  // Active Sticker Placement Undo / Redo
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
          a.isItalic != b.isItalic ||
          a.isUnderline != b.isUnderline ||
          a.textAlign != b.textAlign ||
          a.opacity != b.opacity ||
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
      if (a.points.length != b.points.length) return true;
      for (int i = 0; i < a.points.length; i++) {
        if (a.points[i] != b.points[i]) return true;
      }
      return false;
    }
    return false;
  }

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
        isItalic: sticker.isItalic,
        isUnderline: sticker.isUnderline,
        textAlign: sticker.textAlign,
        opacity: sticker.opacity,
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
        content: sticker.content.copy(),
      );
    }
    throw ArgumentError('Unknown sticker type: ${sticker.runtimeType}');
  }

  void recordActiveStickerState() {
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

    drawingController.refresh();
  }

  void _initActiveStickerHistory(Object sticker) {
    _activeStickerHistory = [cloneActiveSticker(sticker)];
    _activeStickerHistoryIndex = 0;

    drawingController.onUndo = _undoActiveSticker;
    drawingController.onRedo = _redoActiveSticker;
    drawingController.onCanUndo = _canUndoActiveSticker;
    drawingController.onCanRedo = _canRedoActiveSticker;
    drawingController.refresh();
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
      drawingController.onUndo = null;
      drawingController.onRedo = null;
      drawingController.onCanUndo = null;
      drawingController.onCanRedo = null;
    } else {
      drawingController.onUndo = _undoFallback;
      drawingController.onRedo = _redoFallback;
      drawingController.onCanUndo = _canUndoFallback;
      drawingController.onCanRedo = _canRedoFallback;
    }
    drawingController.refresh();
  }

  void _undoActiveSticker() {
    if (_activeStickerHistoryIndex > 0) {
      _activeStickerHistoryIndex--;
      _activeSticker = cloneActiveSticker(_activeStickerHistory[_activeStickerHistoryIndex]);
      updateSnapshot();
      drawingController.refresh();
      notifyListeners();
    } else if (_activeStickerHistoryIndex == 0) {
      _isUndoingActiveStickerPlacement = true;
      _undoneSticker = _activeSticker;
      _undoneStickerHistory = List.from(_activeStickerHistory);
      _undoneStickerHistoryIndex = _activeStickerHistoryIndex;
      _activeSticker = null;
      _clearActiveStickerHistory();
      _isUndoingActiveStickerPlacement = false;
      updateSnapshot();
      drawingController.refresh();
      notifyListeners();
    }
  }

  void _redoActiveSticker() {
    if (_activeStickerHistoryIndex < _activeStickerHistory.length - 1) {
      _activeStickerHistoryIndex++;
      _activeSticker = cloneActiveSticker(_activeStickerHistory[_activeStickerHistoryIndex]);
      updateSnapshot();
      drawingController.refresh();
      notifyListeners();
    }
  }

  bool _canUndoActiveSticker() => true;
  bool _canRedoActiveSticker() => _activeStickerHistoryIndex < _activeStickerHistory.length - 1;

  void _undoFallback() {
    drawingController.onUndo = null;
    drawingController.undo();
    _undoneSticker = null;
    _undoneStickerHistory.clear();
    _undoneStickerHistoryIndex = -1;
    _clearActiveStickerHistory();
    notifyListeners();
  }

  void _redoFallback() {
    _activeSticker = _undoneSticker;
    _activeStickerHistory = List.from(_undoneStickerHistory);
    _activeStickerHistoryIndex = _undoneStickerHistoryIndex;
    _undoneSticker = null;
    _undoneStickerHistory.clear();
    _undoneStickerHistoryIndex = -1;

    drawingController.onUndo = _undoActiveSticker;
    drawingController.onRedo = _redoActiveSticker;
    drawingController.onCanUndo = _canUndoActiveSticker;
    drawingController.onCanRedo = _canRedoActiveSticker;
    updateSnapshot();
    drawingController.refresh();
    notifyListeners();
  }

  bool _canUndoFallback() {
    final layer = drawingController.activeLayer.value;
    if (layer == null || layer.isLocked) return false;
    return layer.currentIndex > 0;
  }

  bool _canRedoFallback() => true;

  // Stamping / confirm active stickers
  void stampActiveSticker() {
    if (drawingController.isCurrentLayerLocked) return;

    if (_activeSticker is ActiveTextSticker) {
      final sticker = _activeSticker as ActiveTextSticker;
      final Paint paint = drawingController.drawConfig.value.paint.copyWith()..color = sticker.color;
      final textContent = TextContent.data(
        offset: sticker.offset,
        text: sticker.text,
        scale: sticker.scale,
        rotation: sticker.rotation,
        fontSize: sticker.fontSize,
        isBold: sticker.isBold,
        isItalic: sticker.isItalic,
        isUnderline: sticker.isUnderline,
        textAlign: sticker.textAlign,
        opacity: sticker.opacity,
        fontFamily: sticker.fontFamily,
        paint: paint,
      );
      _activeSticker = null;
      _clearActiveStickerHistory();
      drawingController.addContent(textContent);
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
      _activeSticker = null;
      _clearActiveStickerHistory();
      drawingController.addContent(shapeContent);
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
      _activeSticker = null;
      _clearActiveStickerHistory();
      drawingController.addContent(lineContent);
    } else if (_activeSticker is ActiveFreehandLineSticker) {
      final sticker = _activeSticker as ActiveFreehandLineSticker;
      _activeSticker = null;
      _clearActiveStickerHistory();
      drawingController.addContent(sticker.content);
    } else {
      _activeSticker = null;
      _clearActiveStickerHistory();
    }
    updateSnapshot();
    notifyListeners();
  }

  void addTextSticker(String text, Offset position) {
    if (drawingController.isCurrentLayerLocked) return;
    if (_activeSticker != null) {
      stampActiveSticker();
    }
    _activeSticker = ActiveTextSticker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      color: drawingController.drawConfig.value.paint.color,
      fontSize: 24,
      offset: position,
    );
    notifyListeners();
  }

  bool Function(PaintContent) _createInterceptDraw(DrawingController controller) {
    return (content) {
      if (controller.isCurrentLayerLocked) return false;
      if (_activeSticker != null) {
        stampActiveSticker();
      }
      if (!_enableStickers && content is! Lasso && content is! ShapeStickerContent) {
        return false;
      }
      if (content is Circle && content.radius > 0) {
        final double inflation = content.paint.strokeWidth / 2;
        final actualCenter = content.startFromCenter ? content.startPoint : content.center;

        Rect bounds;
        if (content.isEllipse) {
          bounds = Rect.fromPoints(content.startPoint, content.endPoint).inflate(inflation);
        } else {
          bounds = Rect.fromCircle(center: actualCenter, radius: content.radius).inflate(inflation);
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

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: localContent,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is Rectangle && content.startPoint != null && content.endPoint != null) {
        final double inflation = content.paint.strokeWidth / 2;
        final bounds = Rect.fromPoints(content.startPoint!, content.endPoint!).inflate(inflation);

        final localContent = Rectangle.data(
          startPoint: content.startPoint! - bounds.topLeft,
          endPoint: content.endPoint! - bounds.topLeft,
          paint: content.paint,
        );

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: localContent,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is FreehandLine || content is SmoothLine) {
        final List<Offset> points = content is FreehandLine
            ? (content as FreehandLine).points ?? const []
            : (content as SmoothLine).points;
        if (points.isEmpty) return false;

        _activeSticker = ActiveFreehandLineSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is SimpleLine) {
        Offset start = content.startPoint ?? Offset.zero;
        Offset end = content.endPoint ?? Offset.zero;

        if (start == end) {
          end = start + const Offset(100, 100);
        }

        _activeSticker = ActiveStraightLineSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startPoint: start,
          endPoint: end,
          paint: content.paint,
          type: 'SimpleLine',
        );
        updateSnapshot();
        notifyListeners();
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

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: localContent,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is Heart && content.startPoint != null && content.endPoint != null) {
        final path = content.getPath();
        final bounds = path.getBounds().inflate(content.paint.strokeWidth / 2);

        if (bounds.isEmpty) return false;

        final localContent = Heart.data(
          startPoint: content.startPoint! - bounds.topLeft,
          endPoint: content.endPoint! - bounds.topLeft,
          paint: content.paint,
        );

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: localContent,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
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

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: localContent,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is StraightLine && content.startPoint != null && content.endPoint != null) {
        _activeSticker = ActiveStraightLineSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startPoint: content.startPoint!,
          endPoint: content.endPoint!,
          paint: content.paint,
          type: 'StraightLine',
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is Lasso) {
        final drawPath = content.getDrawPath();
        drawPath.path.close();
        final bounds = drawPath.path.getBounds();

        if (bounds.isEmpty) return false;

        final Paint eraserPaint = Paint()
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.clear;

        final historyCopy = controller.getHistory
            .take(controller.currentIndex)
            .map((e) => e.copy())
            .toList();

        controller.addContent(EraserHole(path: drawPath, paint: eraserPaint));

        final ClippedHistoryContent stickerContent = ClippedHistoryContent(
          historyCopy,
          drawPath,
          bounds,
          canvasSize: controller.drawConfig.value.size,
        );

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: stickerContent,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is ShapeStickerContent) {
        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content.child,
          offset: content.offset,
          scale: content.scale,
          rotation: content.rotation,
          size: content.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is GroupContent) {
        if (content.children.isEmpty) return false;

        final bounds = content.getPath().getBounds();
        if (bounds.isEmpty) return false;

        content.boundsOffset = -bounds.topLeft;

        _activeSticker = ActiveShapeSticker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          offset: bounds.center,
          size: bounds.size,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      } else if (content is TextContent) {
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
          isItalic: content.isItalic,
          isUnderline: content.isUnderline,
          textAlign: content.textAlign,
          opacity: content.opacity,
        );
        updateSnapshot();
        notifyListeners();
        return true;
      }
      return false;
    };
  }

  @override
  void dispose() {
    for (var controller in _canvases) {
      controller.drawConfig.removeListener(_onDrawConfigChanged);
      controller.dispose();
    }
    super.dispose();
  }
}
