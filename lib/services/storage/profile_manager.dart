import 'package:hive/hive.dart';
import 'package:ish_tissuemap_fusion/models/chronos_snapshot.dart';
import 'package:ish_tissuemap_fusion/models/user_profile.dart';
import 'package:ish_tissuemap_fusion/services/storage/local_database.dart';

class ProfileManager {
  final Box<UserProfile> _profileBox = Hive.box<UserProfile>('profiles');
  final LocalDatabase _db = LocalDatabase();
  UserProfile? _currentProfile;

  List<UserProfile> getAllProfiles() => _profileBox.values.toList();

  Future<void> addProfile(UserProfile profile) async => _profileBox.put(profile.id, profile);

  Future<void> deleteProfile(String id) async => _profileBox.delete(id);

  void setCurrentProfile(UserProfile profile) => _currentProfile = profile;

  UserProfile? get currentProfile => _currentProfile;

  Future<void> addScanToProfile(String profileId, String scanId) async {
    final profile = _profileBox.get(profileId);
    if (profile == null) return;
    profile.scanIds.add(scanId);
    await _profileBox.put(profile.id, profile);
  }

  Future<List<ChronosSnapshot>> getScansForProfile(String profileId) async {
    final profile = _profileBox.get(profileId);
    if (profile == null) return [];
    final all = await _db.getAllSnapshots();
    final ids = profile.scanIds.toSet();
    return all.where((snapshot) => ids.contains(snapshot.id)).toList();
  }
}
