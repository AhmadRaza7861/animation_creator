import 'package:flutter/material.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
const List<BlendMode> _kCommonBlendModes = [
  BlendMode.srcOver,
  BlendMode.multiply,
  BlendMode.screen,
  BlendMode.overlay,
  BlendMode.darken,
  BlendMode.lighten,
  BlendMode.colorDodge,
  BlendMode.colorBurn,
  BlendMode.hardLight,
  BlendMode.softLight,
  BlendMode.difference,
  BlendMode.exclusion,
  BlendMode.hue,
  BlendMode.saturation,
  BlendMode.color,
  BlendMode.luminosity,
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
  BlendMode.hardLight: 'Hard Light',
  BlendMode.softLight: 'Soft Light',
  BlendMode.difference: 'Difference',
  BlendMode.exclusion: 'Exclusion',
  BlendMode.hue: 'Hue',
  BlendMode.saturation: 'Saturation',
  BlendMode.color: 'Color',
  BlendMode.luminosity: 'Luminosity',
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
      opacity: layer.opacity,
      blendMode: layer.blendMode,
      history: layer.history.map((e) => e.copy()).toList(),
      currentIndex: layer.currentIndex,
    );
    widget.controller.layers.insert(index, newLayer); // Insert above
    widget.controller.activeLayer.value = newLayer;
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _deleteLayer(LayerData layer) {
    if (widget.controller.layers.length <= 1) return; // Must have at least one layer
    widget.controller.layers.remove(layer);
    if (widget.controller.activeLayer.value == layer) {
      widget.controller.activeLayer.value = widget.controller.layers.first;
    }
    widget.controller.cachedImage = null; // Invalidate deep cache
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
    widget.controller.cachedImage = null;
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _changeOpacity(LayerData layer, double value) {
    layer.opacity = value;
    widget.controller.cachedImage = null;
    widget.controller.updateSnapshot();
    setState(() {});
  }

  void _changeBlendMode(LayerData layer, BlendMode blendMode) {
    layer.blendMode = blendMode;
    widget.controller.cachedImage = null;
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
          color: Colors.white,
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
                    color: Colors.white,
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
                  widget.controller.cachedImage = null;
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
            const Text(
              'Layers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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
        InkWell(
          onTap: () {
            widget.controller.activeLayer.value = layer;
            setState(() {});
          },
          onDoubleTap: () {
             setState(() {
               _expandedLayer = isExpanded ? null : layer;
             });
          },
          child: Container(
            color: isActive ? Colors.pink.withOpacity(0.1) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleVisibility(layer),
                  child: Icon(
                    layer.isVisible ? Icons.visibility : Icons.visibility_off,
                    color: layer.isVisible ? Colors.black87 : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    layer.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? Colors.pink : Colors.black87,
                      fontSize: 14,
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
                  onTap: () {
                    setState(() {
                      _expandedLayer = isExpanded ? null : layer;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black45,
                    size: 20,
                  ),
                ),
              ],
            ),
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
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: layer.opacity,
                    activeColor: Colors.pink,
                    inactiveColor: Colors.pink.withOpacity(0.2),
                    onChanged: (v) => _changeOpacity(layer, v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(layer.opacity * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BlendMode>(
                      isExpanded: true,
                      isDense: true,
                      value: _kCommonBlendModes.contains(layer.blendMode) ? layer.blendMode : BlendMode.srcOver,
                      icon: const Icon(Icons.unfold_more_rounded, size: 16, color: Colors.black54),
                      items: _kCommonBlendModes.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(
                            _kBlendModeLabels[mode] ?? mode.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3C3043),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (mode) {
                        if (mode != null) _changeBlendMode(layer, mode);
                      },
                    ),
                  ),
                ),
              ),
            ],
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
            Icon(Icons.add_circle, color: Colors.pink, size: 20),
            SizedBox(width: 8),
            Text(
              'New Layer',
              style: TextStyle(
                color: Colors.pink,
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
