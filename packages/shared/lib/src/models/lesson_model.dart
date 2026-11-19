enum LessonType { standard, conversation }

class LessonItem {
  final String id;
  final String speaker; // "A", "B", or "" for standard
  final String arabic;
  final String transliteration;
  final String meaning;
  final String? audioUrl;
  final String? imageUrl;

  const LessonItem({
    required this.id,
    this.speaker = '',
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    this.audioUrl,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'speaker': speaker,
      'arabic': arabic,
      'transliteration': transliteration,
      'meaning': meaning,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
    };
  }

  factory LessonItem.fromMap(Map<String, dynamic> map) {
    return LessonItem(
      id: map['id']?.toString() ?? '',
      speaker: map['speaker']?.toString() ?? '',
      arabic: map['arabic']?.toString() ?? '',
      transliteration: map['transliteration']?.toString() ?? '',
      meaning: map['meaning']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
    );
  }
}

class LessonModel {
  final String id;
  final String title;
  final LessonType type;
  final bool isPublished;
  final List<LessonItem> items;
  final DateTime updatedAt;

  const LessonModel({
    required this.id,
    required this.title,
    required this.type,
    required this.isPublished,
    required this.items,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.name,
      'isPublished': isPublished,
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LessonModel.fromDoc(String id, Map<String, dynamic> data) {
    final rawItems = (data['items'] as List<dynamic>? ?? []);
    return LessonModel(
      id: id,
      title: data['title']?.toString() ?? 'Tanpa Judul',
      type: data['type']?.toString() == 'conversation'
          ? LessonType.conversation
          : LessonType.standard,
      isPublished: data['isPublished'] == true,
      items: rawItems
          .whereType<Map>()
          .map((m) => LessonItem.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
