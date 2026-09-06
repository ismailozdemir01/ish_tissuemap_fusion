import 'package:hive/hive.dart';
import 'anomaly_report.dart';
import 'chronos_snapshot.dart';
import 'medication.dart';
import 'user_profile.dart';

class AnomalyReportAdapter extends TypeAdapter<AnomalyReport> {
  @override
  final int typeId = 4;

  @override
  AnomalyReport read(BinaryReader reader) => AnomalyReport(
        id: reader.read() as String,
        date: reader.read() as DateTime,
        findings: List<String>.from(reader.read() as List),
      );

  @override
  void write(BinaryWriter writer, AnomalyReport obj) {
    writer
      ..write(obj.id)
      ..write(obj.date)
      ..write(obj.findings);
  }
}

class ChronosSnapshotAdapter extends TypeAdapter<ChronosSnapshot> {
  @override
  final int typeId = 1;

  @override
  ChronosSnapshot read(BinaryReader reader) => ChronosSnapshot(
        id: reader.read() as String,
        timestamp: reader.read() as DateTime,
        pointData: List<Map<String, dynamic>>.from(
          (reader.read() as List).map((e) => Map<String, dynamic>.from(e as Map)),
        ),
        report: reader.read() as AnomalyReport?,
        averageFusionScore: (reader.read() as num).toDouble(),
      );

  @override
  void write(BinaryWriter writer, ChronosSnapshot obj) {
    writer
      ..write(obj.id)
      ..write(obj.timestamp)
      ..write(obj.pointData)
      ..write(obj.report)
      ..write(obj.averageFusionScore);
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) => UserProfile(
        id: reader.read() as String,
        name: reader.read() as String,
        relation: reader.read() as String,
        age: reader.read() as int,
        scanIds: List<String>.from(reader.read() as List),
      );

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..write(obj.id)
      ..write(obj.name)
      ..write(obj.relation)
      ..write(obj.age)
      ..write(obj.scanIds);
  }
}

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 3;

  @override
  Medication read(BinaryReader reader) => Medication(
        id: reader.read() as String,
        name: reader.read() as String,
        dosage: reader.read() as String,
        addedDate: reader.read() as DateTime,
        reminders: List<Map<String, String>>.from(
          (reader.read() as List).map((e) => Map<String, String>.from(e as Map)),
        ),
      );

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..write(obj.id)
      ..write(obj.name)
      ..write(obj.dosage)
      ..write(obj.addedDate)
      ..write(obj.reminders);
  }
}
