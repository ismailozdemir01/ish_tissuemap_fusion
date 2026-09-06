import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/connection_screen.dart';
import 'core/app_theme.dart';
import 'models/chronos_snapshot.dart';
import 'models/user_profile.dart';
import 'models/medication.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive veritabanını başlat
  await Hive.initFlutter();
  Hive.registerAdapter(ChronosSnapshotAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(MedicationAdapter());
  await Hive.openBox<ChronosSnapshot>('chronos');
  await Hive.openBox<UserProfile>('profiles');
  await Hive.openBox<Medication>('medications');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISH TissueMap Fusion',
      theme: AppTheme.darkTheme,
      home: const ConnectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
