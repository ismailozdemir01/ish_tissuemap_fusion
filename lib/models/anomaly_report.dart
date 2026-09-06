import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class AnomalyReport {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final List<String> findings;

  const AnomalyReport({
    required this.id,
    required this.date,
    required this.findings,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'findings': findings,
      };
}
