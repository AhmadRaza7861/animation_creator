enum TemplateMode {
  useTemplate,
  drawAccordingTemplate,
}

class TemplateModel {
  final String id;
  final String name;
  final String folder;
  final String extension;
  final int frameCount;
  final List<String> frameAssets;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.folder,
    required this.extension,
    required this.frameCount,
    required this.frameAssets,
  });

  String get previewAsset => frameAssets.isEmpty ? '' : frameAssets.first;
}
