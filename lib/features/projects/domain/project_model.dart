class ProjectMeta {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final String? thumbnailPath;
  final int? fps;
  final int? frameCount;

  ProjectMeta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    this.thumbnailPath,
    this.fps,
    this.frameCount,
  });

  factory ProjectMeta.fromJson(Map<String, dynamic> json) {
    return ProjectMeta(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      thumbnailPath: json['thumbnailPath'] as String?,
      fps: json['fps'] as int?,
      frameCount: json['frameCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'fps': fps,
      'frameCount': frameCount,
    };
  }
}

class ProjectData {
  final ProjectMeta meta;
  final Map<String, dynamic> state;

  ProjectData({
    required this.meta,
    required this.state,
  });
}
