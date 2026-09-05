import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class Medication {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String dosage;
  @HiveField(3)
  DateTime addedDate;
  @HiveField(4)
  List<Map<String, String>> reminders;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.addedDate,
    this.reminders = const [],
  });
}
