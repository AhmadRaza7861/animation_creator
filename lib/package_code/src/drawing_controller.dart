import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'helper/safe_value_notifier.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/paint_content.dart';
import 'paint_contents/simple_line.dart';
import 'paint_contents/smooth_line.dart';
import 'paint_contents/fill.dart';
import 'paint_contents/layer_data.dart';
import 'paint_extension/ex_paint.dart';
import 'helper/flood_fill.dart';
import 'paint_contents/eyedropper.dart';
import 'paint_contents/blur.dart';
import 'paint_contents/smudge.dart';
import 'paint_contents/lasso.dart';
import 'paint_contents/stroke_recolor.dart';
import 'ruler/ruler_config.dart';
import 'ruler/mirror_content.dart';

/// 绘制配置类
///
/// 包含绘制相关的所有配置参数，如画笔样式、颜色、粗细、画板旋转角度等
///
/// Drawing Configuration Class
///
/// Contains all configuration parameters related to drawing, such as brush style,
/// color, thickness, board rotation angle, etc.
class DrawConfig {
  DrawConfig({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.black,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 10,
    this.strength = 0.5,
    this.tolerance = 0.15,
    this.style = PaintingStyle.stroke,
  });

  DrawConfig.def({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.black,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 10,
    this.strength = 0.5,
    this.tolerance = 0.15,
    this.style = PaintingStyle.stroke,
  });

  /// 旋转的角度（0:0°, 1:90°, 2:180°, 3:270°）
  ///
  /// Rotation angle (0:0°, 1:90°, 2:180°, 3:270°)
  final int angle;

  /// 绘制内容类型
  ///
  /// Type of drawing content
  final Type contentType;

  /// 当前触摸的手指数量
  ///
  /// Number of fingers currently touching
  final int fingerCount;

  /// 画板尺寸
  ///
  /// Board size
  final Size? size;

  /// 混合模式
  ///
  /// Blend mode for painting
  final BlendMode blendMode;

  /// 画笔颜色
  ///
  /// Brush color
  final Color color;

  /// 颜色滤镜
  ///
  /// Color filter
  final ColorFilter? colorFilter;

  /// 滤镜质量
  ///
  /// Filter quality
  final FilterQuality filterQuality;

  /// 图像滤镜
  ///
  /// Image filter
  final ui.ImageFilter? imageFilter;

  /// 是否反转颜色
  ///
  /// Whether to invert colors
  final bool invertColors;

  /// 是否启用抗锯齿
  ///
  /// Whether anti-aliasing is enabled
  final bool isAntiAlias;

  /// 遮罩滤镜
  ///
  /// Mask filter
  final MaskFilter? maskFilter;

  /// 着色器
  ///
  /// Shader
  final Shader? shader;

  /// 线帽样式
  ///
  /// Stroke cap style
  final StrokeCap strokeCap;

  /// 线条连接样式
  ///
  /// Stroke join style
  final StrokeJoin strokeJoin;

  /// 线条粗细
  ///
  /// Stroke width
  final double strokeWidth;

  /// 强度参数（用于涂抹/模糊工具的力度）
  ///
  /// Strength parameter (for Smudge/Blur tool intensity)
  final double strength;

  /// 容差参数（用于油漆桶工具的边界检测）
  ///
  /// Color tolerance parameter (for Paint Bucket boundary detection)
  final double tolerance;

  /// 绘制样式（填充或描边）
  ///
  /// Painting style (fill or stroke)
  final PaintingStyle style;

  /// 根据当前配置生成Paint对象
  ///
  /// Generate Paint object based on current configuration
  Paint get paint => Paint()
    ..blendMode = blendMode
    ..color = color
    ..colorFilter = colorFilter
    ..filterQuality = filterQuality
    ..imageFilter = imageFilter
    ..invertColors = invertColors
    ..isAntiAlias = isAntiAlias
    ..maskFilter = maskFilter
    ..shader = shader
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeWidth = strokeWidth
    ..style = style;

  DrawConfig copyWith({
    Type? contentType,
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeWidth,
    double? strength,
    double? tolerance,
    PaintingStyle? style,
    int? angle,
    int? fingerCount,
    Size? size,
  }) {
    return DrawConfig(
      contentType: contentType ?? this.contentType,
      angle: angle ?? this.angle,
      blendMode: blendMode ?? this.blendMode,
      color: color ?? this.color,
      colorFilter: colorFilter ?? this.colorFilter,
      filterQuality: filterQuality ?? this.filterQuality,
      imageFilter: imageFilter ?? this.imageFilter,
      invertColors: invertColors ?? this.invertColors,
      isAntiAlias: isAntiAlias ?? this.isAntiAlias,
      maskFilter: maskFilter ?? this.maskFilter,
      shader: shader ?? this.shader,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strength: strength ?? this.strength,
      tolerance: tolerance ?? this.tolerance,
      style: style ?? this.style,
      fingerCount: fingerCount ?? this.fingerCount,
      size: size ?? this.size,
    );
  }
}

/// 全局工具状态管理
/// Global Tool State Management
class GlobalToolState extends ChangeNotifier {
  static final GlobalToolState instance = GlobalToolState._();
  
  GlobalToolState._() {
    toolConfig = SafeValueNotifier<DrawConfig>(
      DrawConfig.def(contentType: FreehandLine),
    );
    rulerConfig = SafeValueNotifier<RulerConfig>(RulerConfig());
    paintContent = FreehandLine()..paint = toolConfig.value.paint;
  }

  late final SafeValueNotifier<DrawConfig> toolConfig;
  late final SafeValueNotifier<RulerConfig> rulerConfig;
  late PaintContent paintContent;

  double lastEraserWidth = 20.0;
  double lastBrushWidth = 10.0;
  String? activeBrushPresetId;
  String? activeTipLabel;

  void setStyle({
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeWidth,
    double? strength,
    double? tolerance,
    PaintingStyle? style,
  }) {
    if (strokeWidth != null) {
      if (toolConfig.value.contentType == Eraser) {
        lastEraserWidth = strokeWidth;
      } else {
        lastBrushWidth = strokeWidth;
      }
    }
    toolConfig.value = toolConfig.value.copyWith(
      blendMode: blendMode,
      color: color,
      colorFilter: colorFilter,
      filterQuality: filterQuality,
      imageFilter: imageFilter,
      invertColors: invertColors,
      isAntiAlias: isAntiAlias,
      maskFilter: maskFilter,
      shader: shader,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      strokeWidth: strokeWidth,
      strength: strength,
      tolerance: tolerance,
      style: style,
    );
  }

  void setPaintContent(PaintContent content) {
    Type newType = content.runtimeType;

    if (content is! FreehandLine && content is! SmoothLine && content is! SimpleLine) {
      rulerConfig.value = rulerConfig.value.copyWith(type: RulerType.none);
    }

    toolConfig.value = toolConfig.value.copyWith(
      contentType: newType,
    );
    content.paint = toolConfig.value.paint;
    paintContent = content;
  }

  void resetToDefaultBrush() {
    activeBrushPresetId = null;
    activeTipLabel = null;
    rulerConfig.value = rulerConfig.value.copyWith(type: RulerType.none);
    setPaintContent(FreehandLine());
  }
}

/// 绘制控制器
///
/// 管理画板的所有状态和操作，包括绘制内容、历史记录、撤销/重做等功能
/// 提供完整的绘图生命周期 management，支持图片导出、JSON序列化等高级功能
///
/// Drawing Controller
///
/// Manages all states and operations of the drawing board, including drawing content,
/// history, undo/redo functions. Provides complete drawing lifecycle management,
/// supports image export, JSON serialization and other advanced features.
class DrawingController extends ChangeNotifier {
  DrawingController({
    DrawConfig? config,
    PaintContent? content,
    this.maxHistorySteps = 100,
  }) {
    final defaultLayer = LayerData(id: 'layer_0', name: 'Background');
    layers = [defaultLayer];
    activeLayer = SafeValueNotifier<LayerData?>(defaultLayer);

    realPainter = RePaintNotifier();
    painter = RePaintNotifier();
    drawConfig = SafeValueNotifier<DrawConfig>(
      config ?? DrawConfig.def(contentType: GlobalToolState.instance.toolConfig.value.contentType),
    );
    _syncFromGlobal();
    rulerConfig = GlobalToolState.instance.rulerConfig;
    
    GlobalToolState.instance.toolConfig.addListener(_onGlobalToolChange);
  }

  String? get activeBrushPresetId => GlobalToolState.instance.activeBrushPresetId;
  set activeBrushPresetId(String? value) {
    if (GlobalToolState.instance.activeBrushPresetId != value) {
      GlobalToolState.instance.activeBrushPresetId = value;
      notifyListeners();
    }
  }

  String? get activeTipLabel => GlobalToolState.instance.activeTipLabel;
  set activeTipLabel(String? value) {
    GlobalToolState.instance.activeTipLabel = value;
  }

  void _syncFromGlobal() {
    final global = GlobalToolState.instance.toolConfig.value;
    drawConfig.value = drawConfig.value.copyWith(
      contentType: global.contentType,
      blendMode: global.blendMode,
      color: global.color,
      colorFilter: global.colorFilter,
      filterQuality: global.filterQuality,
      imageFilter: global.imageFilter,
      invertColors: global.invertColors,
      isAntiAlias: global.isAntiAlias,
      maskFilter: global.maskFilter,
      shader: global.shader,
      strokeCap: global.strokeCap,
      strokeJoin: global.strokeJoin,
      strokeWidth: global.strokeWidth,
      strength: global.strength,
      style: global.style,
    );
  }

  void _onGlobalToolChange() {
    _syncFromGlobal();
  }

  /// 所有图层
  late List<LayerData> layers;

  /// 当前活跃图层通知器
  late SafeValueNotifier<LayerData?> activeLayer;

  /// 历史记录最大步数，防止内存无限增长
  /// 默认 100 步，可根据需求调整
  ///
  /// Maximum number of history steps to prevent unlimited memory growth
  /// Default is 100 steps, adjustable based on needs
  final int maxHistorySteps;

  /// 原始触摸起点，用于维持平行或同心尺子绘制
  Offset? _startPointRaw;

  /// 原始触摸的最后一个点，用于插值处理（如防切角）
  Offset? _lastPointRaw;

  /// 绘制开始点
  ///
  /// Starting point of drawing
  Offset? _startPoint;

  /// 画板数据Key，用于获取RenderObject导出图片
  ///
  /// Board data key for getting RenderObject to export images
  late GlobalKey painterKey = GlobalKey();

  /// NEW KEY: 用于获取画板内容快照（不含背景），用于模糊/涂抹工具
  late GlobalKey drawingLayerKey = GlobalKey();

  /// 拦截绘制内容回调，如果返回 true则该内容不会被添加到画板历史记录中
  ///
  /// Intercept draw content callback, if returns true, the content will not be added to board history
  bool Function(PaintContent content)? interceptDraw;

  /// Active sticker delegation callbacks
  VoidCallback? onUndo;
  VoidCallback? onRedo;
  bool Function()? onCanUndo;
  bool Function()? onCanRedo;

  /// 绘制配置通知器
  /// Drawing configuration notifier
  late SafeValueNotifier<DrawConfig> drawConfig;

  /// 尺子配置通知器
  /// Ruler configuration notifier
  late SafeValueNotifier<RulerConfig> rulerConfig;

  /// 最后一次设置的绘制内容模板
  ///
  /// Last set drawing content template
  PaintContent get _paintContent => GlobalToolState.instance.paintContent;

  /// 获取当前绘制内容模板
  ///
  /// Get current drawing content template
  PaintContent get currentContent => _paintContent;

  /// 当前正在绘制的内容（实时）
  ///
  /// Currently drawing content (real-time)
  PaintContent? drawingContent;

  /// 橡皮擦绘制内容
  ///
  /// Eraser drawing content
  PaintContent? eraserContent;

  /// 缓存的图片数据，用于优化橡皮擦性能
  ///
  /// Cached image data for optimizing eraser performance
  ui.Image? cachedImage;
  Uint8List? cachedRgbaData;
  int? cachedRgbaWidth;
  int? cachedRgbaHeight;

  /// 清除栅格与图层快照缓存
  void _invalidateRasterCache() {
    cachedImage = null;
    cachedRgbaData = null;
    cachedRgbaWidth = null;
    cachedRgbaHeight = null;
  }

  /// Callback to obtain the canvas background image/template if present
  ui.Image? Function()? backgroundSnapshotProvider;

  /// Optional background image for the board
  ui.Image? backgroundImage;

  /// Opacity for the background image
  double backgroundImageOpacity = 1.0;

  /// 同步生成当前活跃图层的快照图片（用于涂抹/模糊工具）
  ui.Image? generateActiveLayerSnapshotSync([Size? customSize]) {
    final Size? size = customSize ?? drawConfig.value.size;
    if (size == null || size.isEmpty || size.width <= 0 || size.height <= 0) return null;
    final double pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final int targetWidth = (size.width * pixelRatio).round();
    final int targetHeight = (size.height * pixelRatio).round();
    if (targetWidth <= 0 || targetHeight <= 0) return null;

    final LayerData? active = activeLayer.value;
    if (active == null || !active.isVisible) return null;

    final int count = active.currentIndex.clamp(0, active.history.length);
    final ui.Image? bgImg = backgroundSnapshotProvider?.call() ?? backgroundImage;
    if (count == 0 && bgImg == null) {
      return null;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas tempCanvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    );
    tempCanvas.scale(pixelRatio);

    tempCanvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..blendMode = active.blendMode
        ..color = Colors.white.withValues(alpha: active.opacity),
    );

    if (layers.isNotEmpty && active == layers.last && bgImg != null) {
      paintImage(
        canvas: tempCanvas,
        rect: Offset.zero & size,
        image: bgImg,
        fit: BoxFit.cover,
      );
    }

    active.drawHistory(tempCanvas, size, true);

    tempCanvas.restore();

    final ui.Picture picture = recorder.endRecording();
    return picture.toImageSync(targetWidth, targetHeight);
  }

  /// 同步生成当前画板的快照图片（0ms延迟，用于模糊和涂抹工具）
  ui.Image? generateSnapshotSync([Size? customSize]) {
    final Size? size = customSize ?? drawConfig.value.size;
    if (size == null || size.isEmpty || size.width <= 0 || size.height <= 0) return null;
    final double pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final int targetWidth = (size.width * pixelRatio).round();
    final int targetHeight = (size.height * pixelRatio).round();
    if (targetWidth <= 0 || targetHeight <= 0) return null;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas tempCanvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    );
    tempCanvas.scale(pixelRatio);

    tempCanvas.saveLayer(Offset.zero & size, Paint());

    final ui.Image? bgImg = backgroundSnapshotProvider?.call() ?? backgroundImage;
    if (bgImg != null) {
      tempCanvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: backgroundImageOpacity),
      );
      paintImage(
        canvas: tempCanvas,
        rect: Offset.zero & size,
        image: bgImg,
        fit: BoxFit.cover,
      );
      tempCanvas.restore();
    }

    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.isVisible) continue;

      tempCanvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity),
      );

      layer.drawHistory(tempCanvas, size, true);
      tempCanvas.restore();
    }

    tempCanvas.restore();

    final ui.Picture picture = recorder.endRecording();
    return picture.toImageSync(targetWidth, targetHeight);
  }

  /// 预先准备画板快照（当切换到模糊/涂抹工具时调用）
  void prepareSnapshot() {
    if (drawConfig.value.size != null) {
      final ui.Image? snapshot = generateActiveLayerSnapshotSync(drawConfig.value.size) ??
          generateSnapshotSync(drawConfig.value.size);
      if (snapshot != null) {
        cachedImage = snapshot;
        snapshot.toByteData(format: ui.ImageByteFormat.rawRgba).then((ByteData? data) {
          if (data != null) {
            cachedRgbaData = data.buffer.asUint8List();
            cachedRgbaWidth = snapshot.width;
            cachedRgbaHeight = snapshot.height;
          }
        });
      }
    }
  }

  /// 上次渲染的历史总索引，用于避免 _DeepPainter 使用静态跨实例缓存
  int lastTotalIndex = -1;

  /// 上次渲染的尺寸，用于 _DeepPainter 缓存比对
  Size? lastRenderedSize;

  /// 画布背景颜色
  /// Canvas background color
  Color backgroundColor = Colors.white;

  /// 实时快照图片，反映由于绘制或贴纸操作引起的即时变化
  ///
  /// Real-time snapshot image, reflecting immediate changes from drawing or stickers
  final SafeValueNotifier<ui.Image?> realTimeSnapshot = SafeValueNotifier<ui.Image?>(null);

  /// 当前controller是否已挂载
  ///
  /// Whether the controller is currently mounted
  bool _mounted = true;

  /// 获取绘制历史记录
  ///
  /// Get drawing history
  List<PaintContent> get getHistory => activeLayer.value?.history ?? [];

  /// 表层画布刷新通知器
  ///
  /// Surface canvas repaint notifier
  RePaintNotifier? painter;

  /// 底层画布刷新通知器
  ///
  /// Deep layer canvas repaint notifier
  RePaintNotifier? realPainter;

  /// 检查当前活跃图层是否被锁定
  ///
  /// Check if the currently active layer is locked
  bool get isCurrentLayerLocked => activeLayer.value?.isLocked ?? false;

  /// 是否绘制了有效内容（用于判断点击与绘制）
  ///
  /// Whether valid content has been drawn (for distinguishing click from drawing)
  bool _isDrawingValidContent = false;
  bool get isDrawingValidContent => _isDrawingValidContent;

  /// 实时覆盖层绘制钩子（用于未栅格化的贴纸、文本、形状等）
  /// Real-time overlay painter hook (e.g. for active stickers / text / shapes)
  void Function(Canvas canvas, Size size)? activeOverlayPainter;

  /// 获取当前步骤索引
  ///
  /// Get current step index
  int get currentIndex => activeLayer.value?.currentIndex ?? 0;

  /// 获取所有图层的总历史索引，用于缓存验证
  int get totalCurrentIndex => layers.fold(0, (sum, layer) => sum + layer.currentIndex);

  /// 获取当前画笔颜色
  ///
  /// Get current brush color
  Color get getColor => drawConfig.value.color;

  /// 能否开始绘制（无手指或单指触摸进入时）
  ///
  /// Whether drawing can start (when at most single finger is touching)
  bool get couldStartDraw => drawConfig.value.fingerCount <= 1;

  /// 能否进行绘制（单指触摸时）
  ///
  /// Whether drawing is allowed (when at most single finger is touching)
  bool get couldDrawing => drawConfig.value.fingerCount <= 1;

  /// 是否有正在绘制的内容
  ///
  /// Whether there is content being drawn
  bool get hasPaintingContent =>
      drawingContent != null || eraserContent != null;

  /// 获取绘制开始点
  ///
  /// Get drawing start point
  Offset? get startPoint => _startPoint;

  /// Set drawing board size
  void setBoardSize(Size? size) {
    final Size? oldSize = drawConfig.value.size;
    drawConfig.value = drawConfig.value.copyWith(size: size);
    if (size != null && !size.isEmpty && (oldSize != size || realTimeSnapshot.value == null)) {
      updateSnapshot();
    }
  }

  /// Explicitly clear and nullify the drawing board size, forcing LayoutConstraints to regenerate metrics.
  void clearBoardSize() {
    drawConfig.value = DrawConfig(
      contentType: drawConfig.value.contentType,
      angle: drawConfig.value.angle,
      blendMode: drawConfig.value.blendMode,
      color: drawConfig.value.color,
      colorFilter: drawConfig.value.colorFilter,
      filterQuality: drawConfig.value.filterQuality,
      imageFilter: drawConfig.value.imageFilter,
      invertColors: drawConfig.value.invertColors,
      isAntiAlias: drawConfig.value.isAntiAlias,
      maskFilter: drawConfig.value.maskFilter,
      shader: drawConfig.value.shader,
      strokeCap: drawConfig.value.strokeCap,
      strokeJoin: drawConfig.value.strokeJoin,
      strokeWidth: drawConfig.value.strokeWidth,
      style: drawConfig.value.style,
      size: null, // Wipe the size clean!
    );
  }

  /// 增加手指计数（手指按下时调用）
  ///
  /// Increment finger count (called when finger is pressed down)
  void addFingerCount(Offset offset) {
    drawConfig.value = drawConfig.value.copyWith(
      fingerCount: drawConfig.value.fingerCount + 1,
    );
  }

  /// 减少手指计数（手指抬起时调用）
  ///
  /// Decrement finger count (called when finger is released)
  void reduceFingerCount(Offset offset) {
    if (drawConfig.value.fingerCount <= 0) {
      return;
    }

    drawConfig.value = drawConfig.value.copyWith(
      fingerCount: drawConfig.value.fingerCount - 1,
    );
  }

  /// 设置绘制样式
  ///
  /// Set drawing style
  void setStyle({
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeMiterLimit,
    double? strokeWidth,
    double? strength,
    double? tolerance,
    PaintingStyle? style,
  }) {
    GlobalToolState.instance.setStyle(
      blendMode: blendMode,
      color: color,
      colorFilter: colorFilter,
      filterQuality: filterQuality,
      imageFilter: imageFilter,
      invertColors: invertColors,
      isAntiAlias: isAntiAlias,
      maskFilter: maskFilter,
      shader: shader,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      strokeWidth: strokeWidth,
      strength: strength,
      tolerance: tolerance,
      style: style,
    );
  }

  /// 设置绘制内容类型（如SimpleLine、Eraser等）
  ///
  /// Set drawing content type (such as SimpleLine, Eraser, etc.)
  void setPaintContent(PaintContent content) {
    GlobalToolState.instance.setPaintContent(content);
  }

  /// 添加一条绘制内容到历史记录
  ///
  /// Add a drawing content to history
  void addContent(PaintContent content) {
    if (activeLayer.value == null || !activeLayer.value!.isVisible || activeLayer.value!.isLocked) return;
    final LayerData layer = activeLayer.value!;
    
    final int hisLen = layer.history.length;
    if (hisLen > layer.currentIndex) {
      layer.history.removeRange(layer.currentIndex, hisLen);
      if (layer.sessionStartIndex > layer.currentIndex) {
        layer.sessionStartIndex = layer.currentIndex;
      }
    }
    layer.history.add(content);
    layer.currentIndex++;
    _invalidateRasterCache();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 将填充内容插入到线条下方（保持线条在填充层之上）
  ///
  /// Insert fill content underneath stroke outlines on the active layer
  void insertFillContent(FillContent content) {
    if (activeLayer.value == null || !activeLayer.value!.isVisible || activeLayer.value!.isLocked) return;
    final LayerData layer = activeLayer.value!;

    final int hisLen = layer.history.length;
    if (hisLen > layer.currentIndex) {
      layer.history.removeRange(layer.currentIndex, hisLen);
      if (layer.sessionStartIndex > layer.currentIndex) {
        layer.sessionStartIndex = layer.currentIndex;
      }
    }

    // Find the insert position: before non-fill drawing contents (so strokes stay on top)
    int insertIndex = layer.currentIndex;
    while (insertIndex > 0 && layer.history[insertIndex - 1] is! FillContent) {
      insertIndex--;
    }

    layer.history.insert(insertIndex, content);
    layer.currentIndex++;
    _invalidateRasterCache();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 将内容插入到历史记录底层（作为背景/底层参考），不破坏已有绘制
  ///
  /// Insert content at the base of history (underneath existing drawings)
  void insertContentAsBase(PaintContent content) {
    if (activeLayer.value == null || !activeLayer.value!.isVisible || activeLayer.value!.isLocked) return;
    final LayerData layer = activeLayer.value!;

    layer.history.insert(0, content);
    layer.currentIndex++;
    _invalidateRasterCache();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// Sets or updates a dedicated Video Layer for this frame.
  ///
  /// Video frames are isolated on a dedicated 'Video Layer' at the bottom of the layer stack
  /// and locked by default to protect the video reference from accidental brush/eraser modifications.
  /// An active, unlocked 'Drawing' layer is positioned above it, enabling rotoscoping, tracing,
  /// and drawing directly over the video frames.
  void setVideoLayer(PaintContent content) {
    // 1. Check if a video layer already exists
    LayerData? videoLayer;
    for (final l in layers) {
      if (l.name == 'Video Layer' || l.id.startsWith('video_layer_')) {
        videoLayer = l;
        break;
      }
    }

    if (videoLayer != null) {
      videoLayer.history = [content];
      videoLayer.currentIndex = 1;
      videoLayer.isLocked = true;
      videoLayer.isVisible = true;
    } else {
      // 2. Create new dedicated Video Layer
      videoLayer = LayerData(
        id: 'video_layer_${DateTime.now().microsecondsSinceEpoch}',
        name: 'Video Layer',
        isLocked: true,
        isVisible: true,
        history: [content],
        currentIndex: 1,
      );

      // Append at the bottom of the layer stack (rendered first)
      layers.add(videoLayer);
    }

    // 3. Ensure an active unlocked Drawing layer exists on top
    LayerData? drawingLayer;
    for (final l in layers) {
      if (l != videoLayer && !l.isLocked) {
        drawingLayer = l;
        break;
      }
    }

    if (drawingLayer == null) {
      drawingLayer = LayerData(
        id: 'layer_${DateTime.now().microsecondsSinceEpoch + 1}',
        name: 'Drawing',
        isLocked: false,
        isVisible: true,
      );
      layers.insert(0, drawingLayer); // Top layer in UI & render order
    }

    // Set drawing layer as active
    activeLayer.value = drawingLayer;

    // Refresh rendering and invalidate caches
    _invalidateRasterCache();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 批量添加多条绘制内容
  ///
  /// Add multiple drawing contents in batch
  void addContents(List<PaintContent> contents) {
    if (activeLayer.value == null || !activeLayer.value!.isVisible || activeLayer.value!.isLocked) return;
    final LayerData layer = activeLayer.value!;

    final int hisLen = layer.history.length;
    if (hisLen > layer.currentIndex) {
      layer.history.removeRange(layer.currentIndex, hisLen);
      if (layer.sessionStartIndex > layer.currentIndex) {
        layer.sessionStartIndex = layer.currentIndex;
      }
    }
    layer.history.addAll(contents);
    layer.currentIndex += contents.length;
    _invalidateRasterCache();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 批量移除绘制内容（例如提取到选择工具中）
  /// 
  /// Remove items from history (e.g. for extracting to a selection)
  void removeContents(Iterable<PaintContent> contents) {
    if (contents.isEmpty || activeLayer.value == null || !activeLayer.value!.isVisible || activeLayer.value!.isLocked) return;
    final LayerData layer = activeLayer.value!;

    final int hisLen = layer.history.length;
    if (hisLen > layer.currentIndex) {
      layer.history.removeRange(layer.currentIndex, hisLen);
    }
    
    // 移除指定的内容
    // Remove specified contents
    layer.history.removeWhere((content) => contents.contains(content));
    
    layer.currentIndex = layer.history.length;
    if (layer.sessionStartIndex > layer.currentIndex) {
      layer.sessionStartIndex = layer.currentIndex;
    }
    _invalidateRasterCache();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 旋转画布（每次旋转90度）
  ///
  /// Rotate canvas (rotate 90 degrees each time)
  void turn() {
    drawConfig.value = drawConfig.value.copyWith(
      angle: (drawConfig.value.angle + 1) % 4,
    );
  }

  /// 开始绘制
  ///
  /// Start drawing
  void startDraw(Offset startPointRaw, [double? pressure]) {
    if (activeLayer.value == null || !activeLayer.value!.isVisible || activeLayer.value!.isLocked) return;

    if (activeLayer.value!.currentIndex == 0 && _paintContent is Eraser) {
      return;
    }

    _startPointRaw = startPointRaw;
    _lastPointRaw = startPointRaw;
    final Offset startPoint = rulerConfig.value.projectPoint(startPointRaw, null);
    _startPoint = startPoint;

    PaintContent? newContent;

    if (_paintContent is Eraser) {
      newContent = _paintContent.copy();
      newContent.paint = drawConfig.value.paint.copyWith();
      newContent.startDraw(startPoint);
      eraserContent = newContent;
      cachedImage = null;
      _refresh();
      _refreshDeep();
    } else if (_paintContent is Eyedropper) {
      newContent = _paintContent.copy();
      newContent.paint = drawConfig.value.paint;
      newContent.startDraw(startPoint);
      _takeSnapshot(startPoint, forEyedropper: true);
      drawingContent = newContent;
    } else if (_paintContent is BlurContent) {
      newContent = _paintContent.copy();
      final blur = newContent as BlurContent;
      blur.strength = drawConfig.value.strength;
      blur.paint = drawConfig.value.paint.copyWith();
      blur.onRepaint = () {
        _refresh();
      };
      final Size? canvasSize = drawConfig.value.size;
      if (canvasSize != null) {
        blur.canvasSize = canvasSize;
        final ui.Image? snapshot = generateActiveLayerSnapshotSync(canvasSize) ??
            generateSnapshotSync(canvasSize);
        if (snapshot != null) {
          blur.setImageData(snapshot, canvasSize);
          if (cachedRgbaData != null && cachedRgbaWidth == snapshot.width && cachedRgbaHeight == snapshot.height) {
            blur.setRgbaData(cachedRgbaData!, cachedRgbaWidth!, cachedRgbaHeight!, canvasSize);
          }
        }
      }
      blur.startDrawWithPressure(startPoint, pressure ?? 1.0);
      drawingContent = blur;
      cachedImage = null;
      _refresh();
      _refreshDeep();
    } else if (_paintContent is SmudgeContent) {
      newContent = _paintContent.copy();
      final smudge = newContent as SmudgeContent;
      smudge.strength = drawConfig.value.strength;
      smudge.paint = drawConfig.value.paint.copyWith();
      smudge.onRepaint = () {
        _refresh();
      };
      final Size? canvasSize = drawConfig.value.size;
      if (canvasSize != null) {
        smudge.canvasSize = canvasSize;
        final ui.Image? snapshot = generateActiveLayerSnapshotSync(canvasSize) ??
            generateSnapshotSync(canvasSize);
        if (snapshot != null) {
          smudge.setImageData(snapshot, canvasSize);
          if (cachedRgbaData != null && cachedRgbaWidth == snapshot.width && cachedRgbaHeight == snapshot.height) {
            smudge.setRgbaData(cachedRgbaData!, cachedRgbaWidth!, cachedRgbaHeight!, canvasSize);
          }
        }
      }
      smudge.startDrawWithPressure(startPoint, pressure ?? 1.0);
      drawingContent = smudge;
      cachedImage = null;
      _refresh();
      _refreshDeep();
    } else if (_paintContent is FillContent) {
      _drawFill(startPoint);
    } else {
      newContent = _paintContent.copy();
      newContent.paint = drawConfig.value.paint;
      newContent.startDraw(startPoint);
      drawingContent = newContent;
    }

    // Wrap in MirrorContent if mirroring
    if (rulerConfig.value.type == RulerType.mirror && newContent != null && newContent is! Eyedropper) {
      if (newContent == eraserContent) {
        eraserContent = MirrorContent(newContent, rulerConfig.value.center, rulerConfig.value.angle);
      } else {
        drawingContent = MirrorContent(newContent, rulerConfig.value.center, rulerConfig.value.angle);
      }
    } else if (rulerConfig.value.type == RulerType.quadMirror && newContent != null && newContent is! Eyedropper) {
      if (newContent == eraserContent) {
        eraserContent = QuadMirrorContent(newContent, rulerConfig.value.center, rulerConfig.value.angle);
      } else {
        drawingContent = QuadMirrorContent(newContent, rulerConfig.value.center, rulerConfig.value.angle);
      }
    }
  }

  /// 执行填充操作
  Future<void> _drawFill(Offset startPoint) async {
    final Size? size = drawConfig.value.size;
    if (size == null || size.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    // 1. First check if user tapped directly on a vector stroke on the active layer
    if (activeLayer.value != null && activeLayer.value!.isVisible && !activeLayer.value!.isLocked) {
      final LayerData layer = activeLayer.value!;
      final PaintContent? hitStroke = _findHitContent(layer, startPoint);
      if (hitStroke != null) {
        final Color newColor = drawConfig.value.color;
        if (hitStroke.paint.color != newColor) {
          final Color oldColor = hitStroke.paint.color;
          hitStroke.paint.color = newColor;
          final int hitIdx = layer.history.indexOf(hitStroke);
          final StrokeRecolorContent recolorContent = StrokeRecolorContent(
            targetItem: hitStroke,
            oldColor: oldColor,
            newColor: newColor,
            targetIndex: hitIdx,
          );
          addContent(recolorContent);
          return;
        }
        return;
      }
    }

    final int width = size.width.round();
    final int height = size.height.round();
    if (width <= 0 || height <= 0) return;

    // 2. Otherwise perform high-precision flood fill for enclosed area / raster pixels
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    canvas.saveLayer(Offset.zero & size, Paint());

    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.isVisible) continue;

      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity),
      );

      layer.drawHistory(canvas, size, true);
      canvas.restore();
    }

    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    final ui.Image snapshotImage = await picture.toImage(width, height);

    final FloodFillResult? fillResult = await FloodFill.fillWithResult(
      image: snapshotImage,
      startPoint: startPoint,
      fillColor: drawConfig.value.color,
      tolerance: drawConfig.value.tolerance,
    );

    if (fillResult != null) {
      final FillContent content = FillContent.data(
        image: fillResult.image,
        paint: drawConfig.value.paint.copyWith(),
        isUnderneath: fillResult.isUnderneath,
      );
      addContent(content);
    }
  }

  PaintContent? _findHitContent(LayerData layer, Offset pt) {
    final int count = layer.currentIndex.clamp(0, layer.history.length);
    for (int i = count - 1; i >= 0; i--) {
      final item = layer.history[i];
      if (item is FillContent || item is Eyedropper || item is StrokeRecolorContent) continue;
      if (_isPointOnContent(item, pt)) {
        return item;
      }
    }
    return null;
  }

  bool _isPointOnContent(PaintContent item, Offset pt) {
    final double baseWidth = item.paint.strokeWidth > 0 ? item.paint.strokeWidth : 4.0;
    final double hitR = (baseWidth * 0.5 + 8.0);
    final double hitRSq = hitR * hitR;

    if (item is SimpleLine) {
      if (item.startPoint != null && item.endPoint != null) {
        return _distToSegmentSq(pt, item.startPoint!, item.endPoint!) <= hitRSq;
      }
    } else if (item is SmoothLine) {
      if (item.points.length == 1) {
        final double d = (pt - item.points.first).distanceSquared;
        return d <= hitRSq;
      }
      for (int i = 0; i < item.points.length - 1; i++) {
        final double w = i < item.strokeWidthList.length ? item.strokeWidthList[i] : baseWidth;
        final double r = (w * 0.5 + 8.0);
        if (_distToSegmentSq(pt, item.points[i], item.points[i + 1]) <= r * r) {
          return true;
        }
      }
      return false;
    } else if (item is FreehandLine) {
      final List<Offset>? pts = item.points;
      if (pts != null && pts.isNotEmpty) {
        if (pts.length == 1) {
          return (pt - pts.first).distanceSquared <= hitRSq;
        }
        for (int i = 0; i < pts.length - 1; i++) {
          if (_distToSegmentSq(pt, pts[i], pts[i + 1]) <= hitRSq) {
            return true;
          }
        }
        return false;
      }
    }

    // General path-based hit testing for all other shapes and brush lines
    final Path path = item.getPath();
    final Rect bounds = path.getBounds();
    if (bounds.isEmpty) return false;

    if (!bounds.inflate(hitR).contains(pt)) {
      return false;
    }

    if (item.paint.style == PaintingStyle.fill) {
      if (path.contains(pt)) return true;
    }

    // Stroke hit testing along path metrics
    for (final metric in path.computeMetrics()) {
      final double len = metric.length;
      if (len <= 0) continue;
      const double step = 5.0;
      for (double d = 0; d <= len; d += step) {
        final ui.Tangent? t = metric.getTangentForOffset(d);
        if (t != null) {
          final double dx = pt.dx - t.position.dx;
          final double dy = pt.dy - t.position.dy;
          if (dx * dx + dy * dy <= hitRSq) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static double _distToSegmentSq(Offset p, Offset a, Offset b) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double l2 = dx * dx + dy * dy;
    if (l2 == 0) {
      final double px = p.dx - a.dx;
      final double py = p.dy - a.dy;
      return px * px + py * py;
    }
    final double t = (((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / l2).clamp(0.0, 1.0);
    final double projX = a.dx + t * dx;
    final double projY = a.dy + t * dy;
    final double diffX = p.dx - projX;
    final double diffY = p.dy - projY;
    return diffX * diffX + diffY * diffY;
  }

  /// 准备画板快照并提取颜色
  ///
  /// Prepare UI snapshot for Eyedropper, Blur, and Smudge
  Future<void> _takeSnapshot(Offset startPoint, {bool forEyedropper = false}) async {
    try {
      final BuildContext? context = forEyedropper 
          ? painterKey.currentContext 
          : drawingLayerKey.currentContext;
      if (context == null) return;
      
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return;

      final ui.Image image = await renderObject.toImage(pixelRatio: 1.0);

      if (forEyedropper) {
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data == null) return;

        // 验证当前工具仍然是吸管
        if (drawingContent is Eyedropper) {
          (drawingContent as Eyedropper).setImageData(
            data.buffer.asUint8List(),
            image.width,
            image.height,
          );
          _refresh(); // 刷新绘制，展示预览
        }
      } else {
        // Blur and Smudge use the whole snapshot image
        // Unwrap MirrorContent if present
        PaintContent? targetContent = drawingContent;
        if (targetContent is MirrorContent) {
          targetContent = targetContent.child;
        }

        if (targetContent is BlurContent) {
          targetContent.setImageData(image);
          _refresh();
        } else if (targetContent is SmudgeContent) {
          targetContent.setImageData(image);
          _refresh();
        }
      }
    } catch (e, stack) {
      debugPrint('获取画板快照失败: $e\n$stack');
    }
  }

  /// 获取画板完整图像（包含背景和所有内容）
  /// [backgroundColor] 背景颜色
  /// [maxDimension] 输出图片的最大边长，用于控制内存占用
  /// [additionalDraw] 如果提供，将在绘制完历史内容后调用，用于绘制贴纸等额外内容
  ///
  /// Capture full image of the drawing board (including background and all content)
  /// [backgroundColor] background color
  /// [maxDimension] maximum side length of the output image to control memory usage
  /// [additionalDraw] if provided, will be called after drawing history content
  Future<ui.Image?> captureFullImage({
    Color backgroundColor = Colors.white,
    double maxDimension = 2048.0,
    void Function(Canvas canvas, Size size)? additionalDraw,
    ui.Image? backgroundImage,
    double backgroundImageOpacity = 1.0,
    ui.Image? templateImage,
  }) async {
    final Size? size = drawConfig.value.size;
    if (size == null || size.isEmpty) return null;

    final double scale = maxDimension / max(size.width, size.height);
    final Size renderSize = size * scale;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Offset.zero & renderSize);

    canvas.scale(scale);

    // Draw background
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    // Draw background image if provided
    if (backgroundImage != null) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: backgroundImageOpacity),
      );
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: backgroundImage,
        fit: BoxFit.cover,
      );
      canvas.restore();
    }

    // Draw template image if provided
    if (templateImage != null) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint(),
      );
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: templateImage,
        fit: BoxFit.contain,
      );
      canvas.restore();
    }

    // Draw all layers
    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.isVisible) continue;

      canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity),
      );

      layer.drawHistory(canvas, size, false);

      // If this is the active layer and we are erasing, apply it here
      if (layer == activeLayer.value && eraserContent != null) {
        eraserContent?.draw(canvas, size, false);
      }

      canvas.restore();
    }

    // Active drawing (non-eraser)
    if (drawingContent != null && eraserContent == null) {
      drawingContent?.draw(canvas, size, false);
    }

    // Stickers and other additional content
    if (additionalDraw != null) {
      additionalDraw(canvas, size);
    }

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(
      renderSize.width.toInt(),
      renderSize.height.toInt(),
    );
  }

  /// 更新实时快照
  /// [additionalDraw] 如果提供，将在绘制完历史和实时内容后调用，用于绘制贴纸等额外内容
  ///
  /// Update real-time snapshot
  /// [additionalDraw] if provided, will be called after drawing history and real-time content
  bool _isUpdatingSnapshot = false;
  bool _hasPendingSnapshotUpdate = false;
  void Function(Canvas, Size)? _pendingAdditionalDraw;
  bool _pendingIncludeBackground = false;

  void updateSnapshot({
    void Function(Canvas canvas, Size size)? additionalDraw,
    bool includeBackground = false,
  }) {
    final drawOverlay = additionalDraw ?? activeOverlayPainter;

    if (_isUpdatingSnapshot) {
      _hasPendingSnapshotUpdate = true;
      _pendingAdditionalDraw = drawOverlay;
      _pendingIncludeBackground = includeBackground;
      return;
    }

    final Size? size = drawConfig.value.size;
    if (size == null || size.isEmpty) return;

    _isUpdatingSnapshot = true;

    // Use a fixed resolution for the snapshot to ensure performance
    const double snapshotSize = 256.0;
    final double scale = snapshotSize / size.longestSide;
    final Size renderSize = size * scale;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Offset.zero & renderSize);

    canvas.scale(scale);

    // Draw background if requested
    if (includeBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    }

    // Deep layer (History)
    // To support BlendMode.clear efficiently, we wrap in a layer
    canvas.saveLayer(Offset.zero & size, Paint());

    // Deep layer (History) and Active drawing
    final activeLayer = this.activeLayer.value;

    for (int i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.isVisible) continue;
      
      canvas.saveLayer(
        Offset.zero & size, 
        Paint()
          ..blendMode = layer.blendMode
          ..color = Colors.white.withValues(alpha: layer.opacity)
      );
      
      layer.drawHistory(canvas, size, false);

      // If this is the active layer, apply any active drawing or eraser
      if (layer == activeLayer) {
        if (drawingContent != null) {
          drawingContent?.draw(canvas, size, false);
        }
        if (eraserContent != null) {
          eraserContent?.draw(canvas, size, false);
        }
      }
      
      canvas.restore();
    }

    // Active sticker or additional overlay
    if (drawOverlay != null) {
      drawOverlay(canvas, size);
    }

    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    picture.toImage(renderSize.width.toInt(), renderSize.height.toInt()).then((img) {
      realTimeSnapshot.value = img;
      _isUpdatingSnapshot = false;
      if (_hasPendingSnapshotUpdate) {
        _hasPendingSnapshotUpdate = false;
        final pendingDraw = _pendingAdditionalDraw;
        final pendingBg = _pendingIncludeBackground;
        _pendingAdditionalDraw = null;
        updateSnapshot(additionalDraw: pendingDraw, includeBackground: pendingBg);
      }
    }).catchError((e) {
      _isUpdatingSnapshot = false;
      if (_hasPendingSnapshotUpdate) {
        _hasPendingSnapshotUpdate = false;
        final pendingDraw = _pendingAdditionalDraw;
        final pendingBg = _pendingIncludeBackground;
        _pendingAdditionalDraw = null;
        updateSnapshot(additionalDraw: pendingDraw, includeBackground: pendingBg);
      }
    });
  }

  /// 取消绘制（不保存当前绘制内容）
  ///
  /// Cancel drawing (do not save current drawing content)
  void cancelDraw() {
    _startPoint = null;
    drawingContent = null;
    eraserContent = null;
  }

  /// 正在绘制（手指移动过程）
  ///
  /// Drawing in progress (finger moving process)
  void drawing(Offset nowPaintRaw, [double? pressure]) {
    if (!hasPaintingContent) {
      return;
    }

    final List<Offset> route = rulerConfig.value.projectRoute(nowPaintRaw, _startPointRaw, _lastPointRaw);
    _lastPointRaw = nowPaintRaw;

    _isDrawingValidContent = true;

    for (final Offset pt in route) {
      if (eraserContent != null) {
        eraserContent?.drawing(pt);
      } else if (drawingContent is SmudgeContent) {
        (drawingContent as SmudgeContent).drawingWithPressure(pt, pressure ?? 1.0);
      } else if (drawingContent is BlurContent) {
        (drawingContent as BlurContent).drawingWithPressure(pt, pressure ?? 1.0);
      } else {
        drawingContent?.drawing(pt);
      }
    }

    if (eraserContent != null) {
      _refresh();
      _refreshDeep();
    } else {
      _refresh();
    }
  }

  /// 结束绘制（手指抬起，保存绘制内容）
  ///
  /// End drawing (finger released, save drawing content)
  void endDraw() {
    if (!hasPaintingContent) {
      return;
    }

    if (!_isDrawingValidContent) {
      // 清理绘制内容
      _startPoint = null;
      _lastPointRaw = null;
      drawingContent = null;
      eraserContent = null;
      return;
    }

    _isDrawingValidContent = false;

    _startPoint = null;
    _lastPointRaw = null;
    
    if (activeLayer.value != null && activeLayer.value!.isVisible && !activeLayer.value!.isLocked) {
      final LayerData currentLayer = activeLayer.value!;
      final int hisLen = currentLayer.history.length;

      if (hisLen > currentLayer.currentIndex) {
        currentLayer.history.removeRange(currentLayer.currentIndex, hisLen);
        if (currentLayer.sessionStartIndex > currentLayer.currentIndex) {
          currentLayer.sessionStartIndex = currentLayer.currentIndex;
        }
      }

      if (eraserContent != null) {
        currentLayer.history.add(eraserContent!);
        currentLayer.currentIndex = currentLayer.history.length;
        eraserContent = null;
      }

      if (drawingContent != null) {
        bool intercepted = false;
        
        if (drawingContent is Eyedropper) {
          intercepted = true;
          final Color? color = (drawingContent as Eyedropper).pickedColor;
          if (color != null) {
            setStyle(color: color);
          }
        } else if (drawingContent is Lasso) {
          intercepted = true;
          interceptDraw?.call(drawingContent!);
        } else if (interceptDraw != null) {
          intercepted = interceptDraw!(drawingContent!);
        }

        final bool isSmudge = drawingContent is SmudgeContent;
        final bool isBlur = drawingContent is BlurContent;
        if (!intercepted) {
          if (drawingContent is SmudgeContent) {
            final smudge = drawingContent as SmudgeContent;
            smudge.finalizeStroke();
            if (smudge.rgbaData != null && smudge.rgbaWidth != null && smudge.rgbaHeight != null) {
              cachedRgbaData = Uint8List.fromList(smudge.rgbaData!);
              cachedRgbaWidth = smudge.rgbaWidth;
              cachedRgbaHeight = smudge.rgbaHeight;
            }
          } else if (drawingContent is BlurContent) {
            final blur = drawingContent as BlurContent;
            blur.commitSnapshot();
            if (blur.rgbaData != null && blur.rgbaWidth != null && blur.rgbaHeight != null) {
              cachedRgbaData = Uint8List.fromList(blur.rgbaData!);
              cachedRgbaWidth = blur.rgbaWidth;
              cachedRgbaHeight = blur.rgbaHeight;
            }
          }
          currentLayer.history.add(drawingContent!);
          currentLayer.currentIndex = currentLayer.history.length;

          // Release heavy working pixel buffers from all earlier raster states in layer history
          if (isSmudge || isBlur) {
            for (int i = 0; i < currentLayer.history.length - 1; i++) {
              final item = currentLayer.history[i];
              if (item is SmudgeContent) {
                item.releaseWorkingBuffers();
              } else if (item is BlurContent) {
                item.releaseWorkingBuffers();
              }
            }
          }
        }
        drawingContent = null;

        // 修剪历史记录，防止内存无限增长
        _trimHistoryIfNeeded(currentLayer);
        if (!isSmudge && !isBlur) {
          _invalidateRasterCache();
        } else {
          cachedImage = null;
        }
      }
    } else {
      eraserContent = null;
      drawingContent = null;
    }

    _refresh();
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 修剪历史记录，保持在最大步数限制内
  ///
  /// Trim history to keep it within the maximum step limit
  void _trimHistoryIfNeeded(LayerData layer) {
    if (layer.history.length > maxHistorySteps) {
      final int removeCount = layer.history.length - maxHistorySteps;
      layer.history.removeRange(0, removeCount);
      layer.currentIndex = layer.history.length;
      _invalidateRasterCache();
    }
  }

  /// 撤销上一步操作
  ///
  /// Undo the last operation
  void undo() {
    if (onUndo != null) {
      onUndo!();
      return;
    }
    final LayerData? layer = activeLayer.value;
    if (layer == null || layer.isLocked) return;
    
    _invalidateRasterCache();
    if (layer.currentIndex > layer.sessionStartIndex) {
      final int lastIndex = layer.currentIndex - 1;
      final item = layer.history[lastIndex];
      if (item is StrokeRecolorContent) {
        item.revert();
      }
      layer.currentIndex = lastIndex;
      _refreshDeep();
      updateSnapshot();
      notifyListeners();
    }
  }

  /// 检查是否可以撤销
  ///
  /// Check if undo is available
  /// Returns true if possible
  bool canUndo() {
    if (onCanUndo != null) {
      return onCanUndo!();
    }
    final LayerData? layer = activeLayer.value;
    if (layer == null || layer.isLocked) return false;
    return layer.currentIndex > layer.sessionStartIndex;
  }

  /// 重做上一步撤销的操作
  ///
  /// Redo the last undone operation
  void redo() {
    if (onRedo != null) {
      onRedo!();
      return;
    }
    final LayerData? layer = activeLayer.value;
    if (layer == null || layer.isLocked) return;
    
    _invalidateRasterCache();
    if (layer.currentIndex < layer.history.length) {
      final item = layer.history[layer.currentIndex];
      if (item is StrokeRecolorContent) {
        item.apply();
      }
      layer.currentIndex = layer.currentIndex + 1;
      _refreshDeep();
      updateSnapshot();
      notifyListeners();
    }
  }

  /// 检查是否可以重做
  ///
  /// Check if redo is available
  /// Returns true if possible
  bool canRedo() {
    if (onCanRedo != null) {
      return onCanRedo!();
    }
    final LayerData? layer = activeLayer.value;
    if (layer == null || layer.isLocked) return false;
    return layer.currentIndex < layer.history.length;
  }

  /// 清空画布所有内容
  ///
  /// Clear all content on the canvas
  void clear() {
    final LayerData? layer = activeLayer.value;
    if (layer == null || layer.isLocked) return;
    
    cachedImage = null;
    layer.history.clear();
    layer.currentIndex = 0;
    layer.sessionStartIndex = 0;
    _refreshDeep();
    updateSnapshot();
    notifyListeners();
  }

  /// 检查是否可以清空
  ///
  /// Check if clear is available
  /// Returns true if possible
  bool canClear() {
    final LayerData? layer = activeLayer.value;
    if (layer == null || layer.isLocked) return false;
    return layer.history.isNotEmpty;
  }

  /// 剪贴板，用于存储复制的内容
  ///
  /// Clipboard for storing copied content
  PaintContent? clipboard;

  /// 复制选择内容
  ///
  /// Copy selected content
  void copySelection(PaintContent content) {
    clipboard = content.copy();
    notifyListeners();
  }

  /// 剪切选择内容
  ///
  /// Cut selected content
  void cutSelection(PaintContent content) {
    copySelection(content);
    // The UI layer handles removing the active sticker after calling this.
  }

  /// 获取剪贴板内容（支持连续粘贴，每次粘贴由 UI 控制偏移）
  ///
  /// Get clipboard content
  PaintContent? getPastedContent() {
    if (clipboard == null) return null;
    return clipboard!.copy();
  }

  /// 获取完整的画板图片数据（包含背景）
  ///
  /// Get complete board image data (including background)
  Future<ByteData?> getImageData({
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
    double? pixelRatio,
  }) async {
    try {
      final BuildContext? context = painterKey.currentContext;
      if (context == null) {
        debugPrint('画板未挂载，无法获取图片数据');
        return null;
      }

      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('渲染对象类型错误，期望 RenderRepaintBoundary');
        return null;
      }

      final double ratio = pixelRatio ?? View.of(context).devicePixelRatio;
      final ui.Image image = await renderObject.toImage(pixelRatio: ratio);

      return await image.toByteData(format: format);
    } catch (e, stack) {
      debugPrint('获取图片数据失败: $e\n$stack');
      return null;
    }
  }

  /// 获取表层图片数据（仅绘制内容，不含背景）
  /// 更快速，使用缓存的图片数据
  ///
  /// Get surface image data (drawing content only, no background)
  /// Faster, uses cached image data
  Future<ByteData?> getSurfaceImageData({
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    try {
      final ui.Image? image = cachedImage;
      if (image == null) {
        debugPrint('缓存图片不存在，请先进行绘制或使用 getImageData()');
        return null;
      }
      return await image.toByteData(format: format);
    } catch (e, stack) {
      debugPrint('获取表层图片数据失败: $e\n$stack');
      return null;
    }
  }

  /// 获取画板内容的JSON列表
  ///
  /// Get JSON list of board content
  Future<List<Map<String, dynamic>>> getJsonList() async {
    // Collect JSON for all layers. 
    // To remain partly compatible, we'll serialize ALL contents from all layers if we want.
    // However, for a true save system, we need to save the layers themselves.
    // For now we just return all contents from all layers inside a single list.
    final List<Map<String, dynamic>> out = [];
    for (final layer in layers) {
      int latestRasterIndex = -1;
      for (int j = layer.history.length - 1; j >= 0; j--) {
        if (layer.history[j] is SmudgeContent || layer.history[j] is BlurContent) {
          latestRasterIndex = j;
          break;
        }
      }
      for (int j = 0; j < layer.history.length; j++) {
        final content = layer.history[j];
        if (j == latestRasterIndex || (content is! SmudgeContent && content is! BlurContent)) {
          await content.prepareExport();
        }
        out.add(content.toJson());
      }
    }
    return out;
  }

  /// 获取所有图层及其完整状态的JSON列表
  ///
  /// Get JSON list of all layers and their full state including history
  Future<List<Map<String, dynamic>>> getLayersConfig() async {
    final List<Map<String, dynamic>> out = [];
    for (final layer in layers) {
      final List<Map<String, dynamic>> historyJson = [];
      final activeHistory = layer.history.sublist(0, layer.currentIndex.clamp(0, layer.history.length));
      
      // Find latest raster content index (SmudgeContent or BlurContent)
      int latestRasterIndex = -1;
      for (int j = activeHistory.length - 1; j >= 0; j--) {
        if (activeHistory[j] is SmudgeContent || activeHistory[j] is BlurContent) {
          latestRasterIndex = j;
          break;
        }
      }

      for (int j = 0; j < activeHistory.length; j++) {
        final content = activeHistory[j];
        // Only the latest raster snapshot needs base64 export!
        // Shadowed intermediate raster states do not need to bloat the JSON file.
        if (j == latestRasterIndex || (content is! SmudgeContent && content is! BlurContent)) {
          await content.prepareExport();
        }
        historyJson.add(content.toJson());
      }
      out.add({
        'id': layer.id,
        'name': layer.name,
        'isVisible': layer.isVisible,
        'isLocked': layer.isLocked,
        'isGuide': layer.isGuide,
        'opacity': layer.opacity,
        'blendMode': layer.blendMode.index,
        'currentIndex': activeHistory.length,
        'history': historyJson,
      });
    }
    return out;
  }

  /// 强制刷新所有图层（在数据恢复后调用）
  ///
  /// Force refresh all layers (call after data restoration)
  void forceRefreshLayers() {
    _refreshDeep();
    _refresh();
  }

  /// 刷新表层画板（实时绘制层）
  ///
  /// Refresh surface board (real-time drawing layer)
  void _refresh() {
    painter?._refresh();
  }

  /// 刷新底层画板（历史记录层）
  ///
  /// Refresh deep layer board (history layer)
  void _refreshDeep() {
    realPainter?._refresh();
  }

  /// 销毁控制器，释放资源
  ///
  /// Dispose controller and release resources
  @override
  void dispose() {
    if (!_mounted) {
      return;
    }

    GlobalToolState.instance.toolConfig.removeListener(_onGlobalToolChange);

    drawConfig.dispose();
    realPainter?.dispose();
    painter?.dispose();

    _mounted = false;

    super.dispose();
  }

  /// 刷新画板并通知监听者
  ///
  /// Refresh board and notify listeners
  void refresh() {
    notifyListeners();
  }
}

/// 画布刷新通知器
///
/// 用于控制CustomPainter的重绘
///
/// Canvas Repaint Notifier
///
/// Used to control repainting of CustomPainter
class RePaintNotifier extends ChangeNotifier {
  void _refresh() {
    notifyListeners();
  }
}

/// 绘制控制器提供者
///
/// 通过InheritedWidget共享DrawingController到子组件树
///
/// Drawing Controller Provider
///
/// Shares DrawingController to the widget tree via InheritedWidget
class DrawingControllerProvider extends InheritedWidget {
  const DrawingControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  final DrawingController controller;

  static DrawingController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DrawingControllerProvider>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(DrawingControllerProvider oldWidget) => false;
}
