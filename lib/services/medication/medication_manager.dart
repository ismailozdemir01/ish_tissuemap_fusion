import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:ish_tissuemap_fusion/models/medication.dart';

class MedicationManager {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Box<Medication> _medBox = Hive.box<Medication>('medications');

  MedicationManager() {
    tz_data.initializeTimeZones();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<String?> scanMedicationBox() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return null;
      final recognizer = TextRecognizer();
      final recognized =
          await recognizer.processImage(InputImage.fromFile(File(image.path)));
      await recognizer.close();
      final name = _extractMedicationName(recognized.text);
      final dosage = _extractDosage(recognized.text);
      final med = Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isNotEmpty ? name : 'Bilinmeyen İlaç',
        dosage: dosage.isNotEmpty ? dosage : 'Bilinmiyor',
        addedDate: DateTime.now(),
        reminders: [],
      );
      await _medBox.put(med.id, med);
      return med.id;
    } catch (_) {
      return null;
    }
  }

  String _extractMedicationName(String text) =>
      RegExp(r'[A-Z]{2,}[0-9]*|[A-Z][a-z]+[0-9]*')
          .firstMatch(text)
          ?.group(0) ??
      '';

  String _extractDosage(String text) =>
      RegExp(r'[0-9]+(\.[0-9]+)?\s*(mg|ml|g|µg|IU)')
          .firstMatch(text)
          ?.group(0) ??
      '';

  Future<void> addReminder(
    String medId,
    DateTime time,
    String repeatInterval,
  ) async {
    final med = _medBox.get(medId);
    if (med == null) return;
    med.reminders.add({
      'time': time.toIso8601String(),
      'repeat': repeatInterval,
    });
    await _medBox.put(med.id, med);
    await _scheduleNotification(
      med.name,
      'İlacınızı almayı unutmayın: ${med.name}',
      time,
    );
  }

  Future<void> _scheduleNotification(
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    const android = AndroidNotificationDetails(
      'medication_channel',
      'İlaç Hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.zonedSchedule(
      id: scheduledTime.millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  List<String> checkInteractions(List<String> medNames) {
    const interactions = <String, List<String>>{
      'Kan sulandırıcı': ['Aspirin', 'Warfarin'],
      'Tansiyon düşürücü': ['Beta bloker', 'ACE inhibitörü'],
    };
    final warnings = <String>[];
    for (final name in medNames) {
      if (interactions.containsKey(name)) {
        warnings.add(
          '$name diğer ilaçlarla etkileşime girebilir. Doktora danışın.',
        );
      }
    }
    return warnings;
  }

  List<Medication> getAllMedications() => _medBox.values.toList();
}
