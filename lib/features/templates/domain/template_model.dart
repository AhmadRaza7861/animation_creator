enum TemplateMode {
  useTemplate,
  drawAccordingTemplate,
}

enum TutorialDifficulty {
  beginner,
  intermediate,
  advanced,
}

extension TutorialDifficultyExt on TutorialDifficulty {
  String get label {
    switch (this) {
      case TutorialDifficulty.beginner:
        return 'Beginner';
      case TutorialDifficulty.intermediate:
        return 'Intermediate';
      case TutorialDifficulty.advanced:
        return 'Advanced';
    }
  }
}

class TemplateModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final TutorialDifficulty difficulty;
  final String folder;
  final String extension;
  final int frameCount;
  final int estimatedMinutes;
  final List<String> frameAssets;
  final bool isPro;
  final bool isCompleted;
  final bool isInProgress;
  final Map<String, dynamic>? projectState;

  const TemplateModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'Animation Basics',
    this.difficulty = TutorialDifficulty.beginner,
    this.folder = '',
    this.extension = '.webp',
    required this.frameCount,
    this.estimatedMinutes = 5,
    this.frameAssets = const [],
    this.isPro = false,
    this.isCompleted = false,
    this.isInProgress = false,
    this.projectState,
  });

  String get previewAsset => frameAssets.isEmpty ? '' : frameAssets.first;

  /// Returns the canvas map for a specific frame index
  Map<String, dynamic>? getCanvasForFrame(int index) {
    if (projectState == null) return null;
    final canvases = projectState!['canvases'] as List<dynamic>?;
    if (canvases == null || canvases.isEmpty) return null;
    if (index < 0 || index >= canvases.length) return null;
    return canvases[index] as Map<String, dynamic>;
  }

  TemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    TutorialDifficulty? difficulty,
    String? folder,
    String? extension,
    int? frameCount,
    int? estimatedMinutes,
    List<String>? frameAssets,
    bool? isPro,
    bool? isCompleted,
    bool? isInProgress,
    Map<String, dynamic>? projectState,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      folder: folder ?? this.folder,
      extension: extension ?? this.extension,
      frameCount: frameCount ?? this.frameCount,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      frameAssets: frameAssets ?? this.frameAssets,
      isPro: isPro ?? this.isPro,
      isCompleted: isCompleted ?? this.isCompleted,
      isInProgress: isInProgress ?? this.isInProgress,
      projectState: projectState ?? this.projectState,
    );
  }
}
