import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class UserProfile {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String relation; // "Kendim", "Annem", "Babam", "Çocuk"
  @HiveField(3)
  int age;
  @HiveField(4)
  List<String> scanIds; // ChronosSnapshot id'leri

  UserProfile({
    required this.id,
    required this.name,
    required this.relation,
    required this.age,
    this.scanIds = const [],
  });
}
