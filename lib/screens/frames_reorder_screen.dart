import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FramesReorderScreen extends StatefulWidget {
  final List<ui.Image?> thumbnails;
  final int currentIndex;

  const FramesReorderScreen({
    super.key,
    required this.thumbnails,
    required this.currentIndex,
  });

  @override
  State<FramesReorderScreen> createState() => _FramesReorderScreenState();
}

class _FramesReorderScreenState extends State<FramesReorderScreen> {
  late List<int> _order;
  late int _active;

  @override
  void initState() {
    super.initState();
    _order = List.generate(widget.thumbnails.length, (i) => i);
    _active = widget.currentIndex;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    setState(() {
      final prevActiveOriginalIndex = _order[_active];
      
      final int item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);

      _active = _order.indexOf(prevActiveOriginalIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Frames', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.blueAccent),
            label: const Text('Done', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context, {'order': _order, 'active': _active});
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        onReorder: _onReorder,
        itemCount: _order.length,
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return Material(
            elevation: 8,
            shadowColor: Colors.black26,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final originalIndex = _order[index];
          final thumb = widget.thumbnails[originalIndex];
          final isSelected = index == _active;
          
          return Container(
            key: ValueKey(originalIndex),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pink.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.pinkAccent.withOpacity(0.5) : Colors.black12,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumb != null 
                    ? RawImage(image: thumb, fit: BoxFit.contain) 
                    : const Icon(Icons.palette_outlined, color: Colors.black26),
                ),
              ),
              title: Text(
                'Frame ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: isSelected 
                ? const Text('Currently Active', style: TextStyle(color: Colors.pinkAccent, fontSize: 12)) 
                : const Text('Tap to set active', style: TextStyle(color: Colors.black54, fontSize: 12)),
              trailing: const Icon(Icons.drag_indicator, color: Colors.black38),
              onTap: () {
                setState(() { _active = index; });
              },
            ),
          );
        }
      ),
    );
  }
}
