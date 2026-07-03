import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  // Replace the exact signature and start of `_loadCanvasData`
  final oldLoadStr = '  void _loadCanvasData() {';
  final newLoadStr = '  Future<void> _loadCanvasData() async {';
  content = content.replaceFirst(oldLoadStr, newLoadStr);

  // Replace the inner decoding loop
  final oldLoop = '''
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final String type = item['type'] as String;
          final PaintContent? content = decodePaintContent(type, item);
          if (content != null) {
            contents.add(content);
          } else {
            debugPrint('Unknown PaintContent type in JSON: \$type');
          }
        }
      }
''';

  final newLoop = '''
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final String type = item['type'] as String;
          if (type == 'ImageContent') {
            final String imageUrl = item['imageUrl'] as String;
            try {
              final ui.Image image = await _getImage(imageUrl);
              contents.add(
                ImageContent.data(
                  startPoint: jsonToOffset(item['startPoint'] as Map<String, dynamic>),
                  size: jsonToOffset(item['size'] as Map<String, dynamic>),
                  imageUrl: imageUrl,
                  image: image,
                  paint: jsonToPaint(item['paint'] as Map<String, dynamic>),
                ),
              );
            } catch (e) {
              debugPrint('Failed to load image for ImageContent: \$e');
            }
          } else {
            final PaintContent? content = decodePaintContent(type, item);
            if (content != null) {
              contents.add(content);
            } else {
              debugPrint('Unknown PaintContent type in JSON: \$type');
            }
          }
        }
      }
''';

  // Normalize line endings for replacement to ensure it works regardless of \r or \n
  final normalizedContent = content.replaceAll('\r\n', '\n');
  final normalizedOldLoop = oldLoop.replaceAll('\r\n', '\n');
  
  if (normalizedContent.contains(normalizedOldLoop)) {
      final updatedContent = normalizedContent.replaceFirst(normalizedOldLoop, newLoop);
      file.writeAsStringSync(updatedContent);
      print('Replacement successful');
  } else {
      print('Could not find loop to replace');
  }
}
