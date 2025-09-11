class MediaFile {
  final String? id;
  final String fileType; // 'audio', 'image', 'video'
  final String filePath;
  final bool isDeleted;
  String? displayName;
  MediaFile({
    this.id,
    required this.fileType,
    required this.filePath,
    this.isDeleted = false,
    this.displayName,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      fileType: json['fileType'],
      filePath: json['filePath'],
      isDeleted: json['isDeleted'] ?? false,
      displayName: json['displayName'],
    );
  }
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final List<MediaFile> mediaFiles;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.mediaFiles,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      tags: List<String>.from(json['tags'] ?? []),
      mediaFiles: (json['mediaFiles'] as List<dynamic>? ?? [])
          .map((item) => MediaFile.fromJson(item))
          .where((file) => file.isDeleted == false)
          .toList(),
    );
  }

}
