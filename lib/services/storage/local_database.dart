import 'package:hive/hive.dart';
import '../../models/chronos_snapshot.dart';

class LocalDatabase {
  Box<ChronosSnapshot> get _snapshots => Hive.box<ChronosSnapshot>('chronos');

  Future<void> saveSnapshot(ChronosSnapshot snapshot) async {
    await _snapshots.put(snapshot.id, snapshot);
  }

  Future<List<ChronosSnapshot>> getAllSnapshots() async {
    final values = _snapshots.values.toList();
    values.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return values;
  }
}
