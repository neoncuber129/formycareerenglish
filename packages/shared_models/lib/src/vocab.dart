List<String> _parseTagsJson(dynamic raw) {
  if (raw == null) {
    return const <String>[];
  }
  if (raw is List) {
    return raw.map((e) => e.toString()).toList(growable: false);
  }
  return const <String>[];
}

/// Applies [updates] to [vocab] (allowed keys: `isArchived` / `is_archived`,
/// `deletedAt` / `deleted_at`) and sets [updatedAt]. Unknown keys are ignored.
Vocab applyVocabBulkUpdates(
  Vocab vocab,
  Map<String, dynamic> updates,
  DateTime updatedAt,
) {
  var isArchived = vocab.isArchived;
  DateTime? deletedAt = vocab.deletedAt;
  var touchDeleted = false;

  bool? readBool(dynamic v) {
    if (v is bool) {
      return v;
    }
    if (v is num) {
      return v != 0;
    }
    return null;
  }

  DateTime? readDeletedAt(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is DateTime) {
      return v;
    }
    if (v is String) {
      if (v.isEmpty) {
        return null;
      }
      return DateTime.tryParse(v);
    }
    return null;
  }

  for (final e in updates.entries) {
    switch (e.key) {
      case 'isArchived':
      case 'is_archived':
        final b = readBool(e.value);
        if (b != null) {
          isArchived = b;
        }
        break;
      case 'deletedAt':
      case 'deleted_at':
        touchDeleted = true;
        deletedAt = readDeletedAt(e.value);
        break;
    }
  }

  if (touchDeleted) {
    return vocab.copyWith(
      updatedAt: updatedAt,
      isArchived: isArchived,
      deletedAt: deletedAt,
      deletedAtCleared: deletedAt == null,
    );
  }
  return vocab.copyWith(
    updatedAt: updatedAt,
    isArchived: isArchived,
  );
}

class Vocab {
  static const Object _unsetDeletedAt = Object();

  const Vocab({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.languagePair,
    required this.createdAt,
    required this.updatedAt,
    required this.nextReviewAt,
    required this.intervalDays,
    required this.easeFactor,
    required this.reviewCount,
    this.partOfSpeech = '',
    this.phonetic = '',
    this.originalSentence = '',
    this.contextParagraph = '',
    this.sourceApp = '',
    this.sourceUrl = '',
    this.imageAnchor = '',
    this.audioUrl = '',
    this.tags = const <String>[],
    this.isArchived = false,
    this.deletedAt,
    this.newLearningStepIndex = -1,
  });

  final String id;
  final String sourceText;
  final String translatedText;
  final String languagePair;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextReviewAt;
  final int intervalDays;
  final double easeFactor;
  final int reviewCount;

  /// Loại từ (noun, verb, …) từ dictionary / enrichment.
  final String partOfSpeech;
  final String phonetic;
  /// Câu chứa thuật ngữ khi capture (SRS cloze).
  final String originalSentence;
  /// Đoạn văn bao quanh để phục dựng bối cảnh.
  final String contextParagraph;
  final String sourceApp;
  final String sourceUrl;
  /// Đường dẫn file ảnh capture (local path hoặc URL sau cloud sync).
  final String imageAnchor;
  final String audioUrl;
  final List<String> tags;

  /// Ẩn khỏi ôn tập chính khi true (vẫn có thể hiện trong danh sách từ vựng).
  final bool isArchived;

  /// Soft delete / Thùng rác; null = đang active.
  final DateTime? deletedAt;

  /// Anki-style new-card learning: `0..n` = intraday learning step; `-1` = day-based SRS only.
  final int newLearningStepIndex;

  /// Alias đọc gần spec Deep Context.
  String get term => sourceText;

  /// Alias đọc gần spec Deep Context.
  String get definition => translatedText;

  factory Vocab.initial({
    required String id,
    required String sourceText,
    required String translatedText,
    required String languagePair,
    String partOfSpeech = '',
    String phonetic = '',
    String originalSentence = '',
    String contextParagraph = '',
    String sourceApp = '',
    String sourceUrl = '',
    String imageAnchor = '',
    String audioUrl = '',
    List<String> tags = const <String>[],
  }) {
    final now = DateTime.now();
    return Vocab(
      id: id,
      sourceText: sourceText,
      translatedText: translatedText,
      languagePair: languagePair,
      createdAt: now,
      updatedAt: now,
      nextReviewAt: now,
      intervalDays: 1,
      easeFactor: 2.5,
      reviewCount: 0,
      partOfSpeech: partOfSpeech,
      phonetic: phonetic,
      originalSentence: originalSentence,
      contextParagraph: contextParagraph,
      sourceApp: sourceApp,
      sourceUrl: sourceUrl,
      imageAnchor: imageAnchor,
      audioUrl: audioUrl,
      tags: List<String>.unmodifiable(List<String>.from(tags)),
      isArchived: false,
      deletedAt: null,
      newLearningStepIndex: 0,
    );
  }

  Vocab copyWith({
    String? id,
    String? sourceText,
    String? translatedText,
    String? languagePair,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextReviewAt,
    int? intervalDays,
    double? easeFactor,
    int? reviewCount,
    String? partOfSpeech,
    String? phonetic,
    String? originalSentence,
    String? contextParagraph,
    String? sourceApp,
    String? sourceUrl,
    String? imageAnchor,
    String? audioUrl,
    List<String>? tags,
    bool? isArchived,
    Object? deletedAt = _unsetDeletedAt,
    /// When true, [deletedAt] may be set to null (restore from trash).
    bool deletedAtCleared = false,
    int? newLearningStepIndex,
  }) {
    final DateTime? nextDeletedAt = deletedAtCleared
        ? null
        : (identical(deletedAt, _unsetDeletedAt)
            ? this.deletedAt
            : deletedAt as DateTime?);
    return Vocab(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      languagePair: languagePair ?? this.languagePair,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewCount: reviewCount ?? this.reviewCount,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      phonetic: phonetic ?? this.phonetic,
      originalSentence: originalSentence ?? this.originalSentence,
      contextParagraph: contextParagraph ?? this.contextParagraph,
      sourceApp: sourceApp ?? this.sourceApp,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageAnchor: imageAnchor ?? this.imageAnchor,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags != null
          ? List<String>.unmodifiable(List<String>.from(tags))
          : this.tags,
      isArchived: isArchived ?? this.isArchived,
      deletedAt: nextDeletedAt,
      newLearningStepIndex:
          newLearningStepIndex ?? this.newLearningStepIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_text': sourceText,
      'translated_text': translatedText,
      'language_pair': languagePair,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'next_review_at': nextReviewAt.toIso8601String(),
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'review_count': reviewCount,
      'part_of_speech': partOfSpeech,
      'phonetic': phonetic,
      'original_sentence': originalSentence,
      'context_paragraph': contextParagraph,
      'source_app': sourceApp,
      'source_url': sourceUrl,
      'image_anchor': imageAnchor,
      'audio_url': audioUrl,
      'tags': tags,
      'is_archived': isArchived,
      'deleted_at': deletedAt?.toIso8601String(),
      'new_learning_step_index': newLearningStepIndex,
    };
  }

  factory Vocab.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(String key, DateTime fallback) {
      final raw = json[key];
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw) ?? fallback;
      }
      return fallback;
    }

    final now = DateTime.now();
    final created = parseDt('created_at', now);
    final updated = parseDt('updated_at', created);
    final nextReview = parseDt('next_review_at', created);

    DateTime? deletedAt;
    final delRaw = json['deleted_at'];
    if (delRaw is String && delRaw.isNotEmpty) {
      deletedAt = DateTime.tryParse(delRaw);
    }

    final iaRaw = json['is_archived'];
    final isArchived = iaRaw is bool
        ? iaRaw
        : (iaRaw is num ? iaRaw != 0 : false);

    final reviewCount = (json['review_count'] as num?)?.toInt() ?? 0;
    final migratedLearningIndex = _migrateNewLearningStepIndexFromJson(
      json,
      reviewCount,
    );

    return Vocab(
      id: json['id'] as String? ?? '',
      sourceText: json['source_text'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      languagePair: json['language_pair'] as String? ?? 'en-vi',
      createdAt: created,
      updatedAt: updated,
      nextReviewAt: nextReview,
      intervalDays: (json['interval_days'] as num?)?.toInt() ?? 1,
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      reviewCount: reviewCount,
      partOfSpeech: json['part_of_speech'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      originalSentence: json['original_sentence'] as String? ?? '',
      contextParagraph: json['context_paragraph'] as String? ?? '',
      sourceApp: json['source_app'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      imageAnchor: json['image_anchor'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      tags: _parseTagsJson(json['tags']),
      isArchived: isArchived,
      deletedAt: deletedAt,
      newLearningStepIndex: migratedLearningIndex,
    );
  }
}

int _migrateNewLearningStepIndexFromJson(
  Map<String, dynamic> json,
  int reviewCount,
) {
  final raw = json['new_learning_step_index'];
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (reviewCount == 0) {
    return 0;
  }
  return -1;
}
