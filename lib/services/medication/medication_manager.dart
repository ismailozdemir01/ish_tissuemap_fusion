import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ish_tissuemap_fusion/models/medication.dart';
import 'package:hive/hive.dart';

/// İlaç yönetim servisi.
/// OCR ile ilaç okuma, hatırlatıcı ve etkileşim kontrolü.
class MedicationManager {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Box<Medication> _medBox = Hive.box<Medication>('medications');

  MedicationManager() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  /// Kamera ile ilaç kutusunu okur ve içindeki metni döndürür.
  Future<String?> scanMedicationBox() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return null;

      final inputImage = InputImage.fromFile(File(image.path));
      final textDetector = GoogleMlKit.vision.textDetector();
      final recognizedText = await textDetector.processImage(inputImage);
      await textDetector.close();

      String fullText = recognizedText.text;
      // İlaç adını ve dozajı çıkarmak için regex veya NLP
      // Örnek basit çıkarım:
      String name = _extractMedicationName(fullText);
      String dosage = _extractDosage(fullText);

      // Kaydet
      final med = Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isNotEmpty ? name : 'Bilinmeyen İlaç',
        dosage: dosage.isNotEmpty ? dosage : 'Bilinmiyor',
        addedDate: DateTime.now(),
        reminders: [],
      );
      await _medBox.put(med.id, med);
      return med.id;
    } catch (e) {
      print('OCR Hatası: $e');
      return null;
    }
  }

  String _extractMedicationName(String text) {
    // Basit regex ile ilaç adı bulma (örnek)
    RegExp nameRegex = RegExp(r'[A-Z]{2,}[0-9]*|[A-Z][a-z]+[0-9]*');
    var match = nameRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractDosage(String text) {
    RegExp dosageRegex = RegExp(r'[0-9]+(\.[0-9]+)?\s*(mg|ml|g|µg|IU)');
    var match = dosageRegex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  /// İlaç hatırlatıcı ekler
  Future<void> addReminder(String medId, DateTime time, String repeatInterval) async {
    final med = _medBox.get(medId);
    if (med == null) return;

    med.reminders.add({'time': time.toIso8601String(), 'repeat': repeatInterval});
    await med.save();

    // Bildirim planla
    await _scheduleNotification(med.name, 'İlacınızı almayı unutmayın: ${med.name}', time);
  }

  Future<void> _scheduleNotification(String title, String body, DateTime scheduledTime) async {
    const android = AndroidNotificationDetails(
      'medication_channel',
      'İlaç Hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    await _notifications.schedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      scheduledTime,
      details,
    );
  }

  /// İlaç etkileşimlerini kontrol eder (basit örnek)
  List<String> checkInteractions(List<String> medNames) {
    // Basit kural tabanlı etkileşim
    Map<String, List<String>> interactions = {
      'Kan sulandırıcı': ['Aspirin', 'Warfarin'],
      'Tansiyon düşürücü': ['Beta bloker', 'ACE inhibitörü'],
    };
    List<String> warnings = [];
    for (var name in medNames) {
      if (interactions.containsKey(name)) {
        warnings.add('$name diğer ilaçlarla etkileşime girebilir. Doktora danışın.');
      }
    }
    return warnings;
  }

  List<Medication> getAllMedications() => _medBox.values.toList();
}
