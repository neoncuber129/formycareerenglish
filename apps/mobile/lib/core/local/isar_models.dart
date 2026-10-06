import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class VocabRecordEntity {
  VocabRecordEntity();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String vocabId;

  late String payloadJson;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;

  @Index()
  late DateTime nextReviewAt;

  @Index()
  late bool isArchived;

  late String syncStatus;

  String? lastError;

  int retryCount = 0;
}

@collection
class AppSettingEntity {
  AppSettingEntity();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  String? stringValue;

  bool? boolValue;
}
