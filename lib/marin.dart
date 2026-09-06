import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/connection_screen.dart';
import 'core/app_theme.dart';
import 'models/chronos_snapshot.dart';
import 'models/user_profile.dart';
import 'models/medication.dart';
import 'models/anomaly_report.dart';
import 'models/hive_adapters.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ChronosSnapshotAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserProfileAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MedicationAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(AnomalyReportAdapter());
  await Hive.openBox<ChronosSnapshot>('chronos');
  await Hive.openBox<UserProfile>('profiles');
  await Hive.openBox<Medication>('medications');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ISH TissueMap Fusion',
        theme: AppTheme.darkTheme,
        home: const ConnectionScreen(),
        debugShowCheckedModeBanner: false,
      );
}
