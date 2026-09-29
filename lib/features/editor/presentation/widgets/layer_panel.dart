import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../../../../package_code/src/paint_contents/layer_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';

class BlendModeInfo {
  final BlendMode mode;
  final String label;
  final String description;
  final String category;
  final IconData icon;

  const BlendModeInfo({
    required this.mode,
    required this.label,
    required this.description,
    required this.category,
    required this.icon,
  });
}

const List<BlendModeInfo> _kCuratedBlendModes = [
  // Standard
  BlendModeInfo(
    mode: BlendMode.srcOver,
    label: 'Normal',
    description: 'Standard rendering without color blending',
    category: 'Standard',
    icon: Icons.layers_outlined,
  ),
  // Darken
  BlendModeInfo(
    mode: BlendMode.multiply,
    label: 'Multiply',
    description: 'Darkens base colors; ideal for shading & shadows',
    category: 'Darken',
    icon: Icons.brightness_4_outlined,
  ),
  BlendModeInfo(
    mode: BlendMode.darken,
    label: 'Darken',
    description: 'Selects the darker of overlapping pixel colors',
    category: 'Darken',
    icon: Icons.dark_mode_outlined,
  ),
  BlendModeInfo(
    mode: BlendMode.colorBurn,
    label: 'Color Burn',
    description: 'Increases contrast and deepens shadows',
    category: 'Darken',
    icon: Icons.local_fire_department_outlined,
  ),
  // Lighten
  BlendModeInfo(
    mode: BlendMode.screen,
    label: 'Screen',
    description: 'Lightens colors; perfect for highlights & glow',
    category: 'Lighten',
    icon: Icons.brightness_7_outlined,
  ),
  BlendModeInfo(
    mode: BlendMode.lighten,
    label: 'Lighten',
    description: 'Selects the lighter of overlapping pixel colors',
    category: 'Lighten',
    icon: Icons.light_mode_outlined,
  ),
  BlendModeInfo(
    mode: BlendMode.colorDodge,
    label: 'Color Dodge',
    description: 'Brightens underlying colors for vibrant glow effects',
    category: 'Lighten',
    icon: Icons.flare_rounded,
  ),
  // Contrast
  BlendModeInfo(
    mode: BlendMode.overlay,
    label: 'Overlay',
    description: 'Combines Multiply and Screen to boost contrast',
    category: 'Contrast',
    icon: Icons.tune_rounded,
  ),
  BlendModeInfo(
    mode: BlendMode.softLight,
    label: 'Soft Light',
    description: 'Creates a subtle, soft diffuse lighting effect',
    category: 'Contrast',
    icon: Icons.wb_twilight_rounded,
  ),
  BlendModeInfo(
    mode: BlendMode.hardLight,
    label: 'Hard Light',
    description: 'Creates bold, dramatic high-contrast lighting',
    category: 'Contrast',
    icon: Icons.flash_on_rounded,
  ),
  // Special
  BlendModeInfo(
    mode: BlendMode.difference,
    label: 'Difference',
    description: 'Inverts colors based on underlying layer differences',
    category: 'Special',
    icon: Icons.compare_arrows_rounded,
  ),
];

const Map<BlendMode, String> _kBlendModeLabels = {
  BlendMode.srcOver: 'Normal',
  BlendMode.multiply: 'Multiply',
  BlendMode.screen: 'Screen',
  BlendMode.overlay: 'Overlay',
  BlendMode.darken: 'Darken',
  BlendMode.lighten: 'Lighten',
  BlendMode.colorDodge: 'Color Dodge',
  BlendMode.colorBurn: 'Color Burn',
  BlendMode.softLight: 'Soft Light',
  BlendMode.hardLight: 'Hard Light',
  BlendMode.difference: 'Difference',
};

class LayerPanel extends StatefulWidget {
  final DrawingController controller;
  final VoidCallback onClose;
  final GestureDragUpdateCallback? onHeaderDrag;

  const LayerPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onHeaderDrag,
  });

  @override
  State<LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends State<LayerPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    setState(() {});
  }

  void _addLayer() {
    final int nextIndex = widget.controller.layers.length + 1;
    final newLayer = LayerData(
      id: 'layer_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Layer $nextIndex',
    );
    widget.controller.layers.insert(0, newLayer); // Insert at top
    widget.controller.activeLayer.value = newLayer;
    widget.controller.refresh();
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _duplicateLayer(LayerData layer) {
    int index = widget.controller.layers.indexOf(layer);
    if (index == -1) return;

    final newLayer = LayerData(
      id: 'layer_${DateTime.now().millisecondsSinceEpoch}',
      name: '${layer.name} Copy',
      isVisible: layer.isVisible,
      isLocked: layer.isLocked,
      isGuide: layer.isGuide,
      opacity: layer.opacity,
      blendMode: layer.blendMode,
      history: layer.history.map((e) => e.copy()).toList(),
      currentIndex: layer.currentIndex,
    );
    widget.controller.layers.insert(index, newLayer); // Insert above
    widget.controller.activeLayer.value = newLayer;
    widget.controller.refresh();
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _deleteLayer(LayerData layer) {
    if (widget.controller.layers.length <= 1) return; // Must have at least one layer
    widget.controller.layers.remove(layer);
    if (widget.controller.activeLayer.value == layer) {
      widget.controller.activeLayer.value = widget.controller.layers.first;
    }
    widget.controller.refresh();
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _toggleLock(LayerData layer) {
    layer.isLocked = !layer.isLocked;
    widget.controller.refresh();
    setState(() {});
  }

  void _toggleVisibility(LayerData layer) {
    layer.isVisible = !layer.isVisible;
    widget.controller.refresh();
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _changeOpacity(LayerData layer, double value) {
    layer.opacity = value;
    widget.controller.refresh();
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _changeBlendMode(LayerData layer, BlendMode blendMode) {
    layer.blendMode = blendMode;
    widget.controller.refresh();
    widget.controller.updateSnapshot();
    setState(() {});
  }

  LayerData? _expandedLayer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: ColorConstants.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  return Material(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    color: ColorConstants.background,
                    child: child,
                  );
                },
                itemCount: widget.controller.layers.length,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  if (oldIndex == newIndex) return;

                  final layer = widget.controller.layers.removeAt(oldIndex);
                  widget.controller.layers.insert(newIndex, layer);
                  
                  // Invalidate cache and redraw
                  widget.controller.refresh();
                  widget.controller.updateSnapshot();
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  final layer = widget.controller.layers[index];
                  return _buildLayerItem(layer, index, key: ValueKey(layer.id));
                },
              ),
            ),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: widget.onHeaderDrag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AssetConstants.layer_icon,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    ColorConstants.darkText,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Layers (${widget.controller.layers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.darkText,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: widget.onClose,
              child: const Icon(Icons.close, size: 20, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerItem(LayerData layer, int index, {Key? key}) {
    final bool isActive = widget.controller.activeLayer.value == layer;
    final bool isExpanded = _expandedLayer == layer;

    return Column(
      key: key,
      children: [
        Container(
          color: isActive ? ColorConstants.accent.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleVisibility(layer),
                child: Icon(
                  layer.isVisible ? Icons.visibility : Icons.visibility_off,
                  color: layer.isVisible ? ColorConstants.darkText : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    widget.controller.activeLayer.value = layer;
                    setState(() {});
                  },
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          layer.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? ColorConstants.accent : ColorConstants.darkText,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (layer.blendMode != BlendMode.srcOver) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: ColorConstants.accent.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _kBlendModeLabels[layer.blendMode] ?? 'Mode',
                            style: const TextStyle(
                              fontSize: 9,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (layer.isLocked) const Icon(Icons.lock, size: 16, color: Colors.redAccent),
              const SizedBox(width: 4),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.drag_indicator, color: Colors.black38, size: 20),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _expandedLayer = isExpanded ? null : layer;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black45,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isExpanded) _buildLayerSettings(layer),
      ],
    );
  }

  Widget _buildLayerSettings(LayerData layer) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.opacity, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: layer.opacity,
                    activeColor: ColorConstants.accent,
                    inactiveColor: ColorConstants.accent.withValues(alpha: 0.2),
                    onChanged: (v) => _changeOpacity(layer, v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(layer.opacity * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, color: ColorConstants.darkText),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Modern Blend Mode Selector Tile
          InkWell(
            onTap: () => _openBlendModeSheet(layer),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      size: 14,
                      color: ColorConstants.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _kBlendModeLabels[layer.blendMode] ?? 'Normal',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.darkText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Blend',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.mediumText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: ColorConstants.mediumText,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: layer.isLocked ? Icons.lock : Icons.lock_open,
                label: 'Lock',
                color: layer.isLocked ? Colors.redAccent : Colors.black54,
                onTap: () => _toggleLock(layer),
              ),
              _buildActionButton(
                icon: Icons.copy,
                label: 'Duplicate',
                color: Colors.black54,
                onTap: () => _duplicateLayer(layer),
              ),
              _buildActionButton(
                icon: Icons.delete,
                label: 'Delete',
                color: widget.controller.layers.length > 1 ? Colors.red : Colors.grey,
                onTap: widget.controller.layers.length > 1 ? () => _deleteLayer(layer) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  void _openBlendModeSheet(LayerData layer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.layers_rounded,
                            color: ColorConstants.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${layer.name} Blend Mode',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  color: ColorConstants.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Select how this layer blends with layers below',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstants.mediumText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded, size: 20, color: ColorConstants.mediumText),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  // List of blend modes
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      shrinkWrap: true,
                      itemCount: _kCuratedBlendModes.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _kCuratedBlendModes[index];
                        final bool isSelected = layer.blendMode == item.mode;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _changeBlendMode(layer, item.mode);
                              setSheetState(() {});
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConstants.primaryLight
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorConstants.accent
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: ColorConstants.accent.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Category icon badge
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? ColorConstants.accent
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 18,
                                      color: isSelected ? Colors.white : ColorConstants.darkText,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Label & Description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Outfit',
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                color: isSelected ? ColorConstants.accent : ColorConstants.darkText,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? ColorConstants.accent.withValues(alpha: 0.15)
                                                    : const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                item.category,
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontFamily: 'Outfit',
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected ? ColorConstants.accent : ColorConstants.mediumText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.description,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontFamily: 'Outfit',
                                            fontWeight: FontWeight.w400,
                                            color: ColorConstants.mediumText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Checkmark indicator
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? ColorConstants.accent : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? ColorConstants.accent : const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return InkWell(
      onTap: _addLayer,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle, color: ColorConstants.accent, size: 20),
            SizedBox(width: 8),
            Text(
              'New Layer',
              style: TextStyle(
                color: ColorConstants.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
