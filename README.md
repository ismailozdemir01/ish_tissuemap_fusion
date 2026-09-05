🧬 ISH TissueMap Fusion

Devrim Niteliğinde Hibrit Vücut Tarama ve Sağlık Asistanı

ISH TissueMap Fusion, akustik dalgalar ve elektromanyetik alan (EMF) sensörlerini birleştirerek vücut dokularını tarayan, yapay zeka destekli, tam donanımlı bir sağlık ekosistemidir.
Telefonunuzu vücudunuzda gezdirerek organ yoğunluğu, iletkenlik, anormallikler ve biyobelirteçler hakkında anlık bilgi alabilir, geçmiş verilerinizle karşılaştırabilir ve doktorunuza profesyonel raporlar sunabilirsiniz.

---

📌 İçindekiler

· Özellikler
· Teknik Mimari
· Kurulum ve Derleme
· Kullanım Kılavuzu
· Dosya Yapısı
· Katkıda Bulunma
· Yol Haritası
· Lisans
· İletişim

---

🚀 Özellikler

🔬 Temel Tarama Motoru

Modül Açıklama
Akustik + EMF Hibrit Tarama 18kHz ses dalgası ve manyetometre ile dokuların yoğunluk ve iletkenlik haritasını çıkarır.
MAC (Motion Artifact Cancellation) Kalman filtresi ile el titremesini ve hareket gürültüsünü matematiksel olarak temizler.
Spektral Doku İmzalayıcı FFT ile frekans bantlarını analiz ederek yağ, kas, tümör gibi doku tiplerini tahmin eder.

🧠 Yapay Zeka ve Analiz

Modül Açıklama
AI Triyaj Asistanı TensorFlow Lite ile offline çalışan model, tarama sonucunu değerlendirir ve eylem önerir.
Kişiselleştirilmiş Sağlık Koçu Verilere göre diyet, egzersiz, uyku ve stres yönetimi önerileri sunar.
Chronos Zaman Tüneli Geçmiş taramaları saklar, trend grafikleri ve overlay karşılaştırması yapar.

👁️ Görüntü ve Sensör Desteği

Modül Açıklama
AR Rehberlik Kamera üzerinde vücut şablonu ve organ etiketleri ile doğru bölgeyi işaretler.
Biyobelirteç Tespiti Cilt, tırnak ve göz fotoğraflarından anemi, sarılık riskini tespit eder.
Sesli Asistan Konuşma tanıma ile komut alma ve metin okuma (TTS) desteği.

📄 Raporlama ve Paylaşım

Modül Açıklama
PDF Rapor Üretici Isı haritası, skorlar, trend grafiği içeren profesyonel rapor oluşturur.
FHIR Entegrasyonu Sağlık verilerini HL7 FHIR standardıyla hastanelere ve doktorlara gönderir.
Acil Durum & Triyaj SOS butonu, konum paylaşımı, semptom analizi ve en yakın sağlık kuruluşuna yönlendirme.

🤝 Sosyal ve Yönetim

Modül Açıklama
Sosyal Topluluk Kullanıcılar sağlık hikayelerini paylaşabilir, meydan okumalara katılabilir.
Aile Profili Yönetimi Birden fazla kullanıcı profili oluşturup her birinin verilerini ayrı saklar.
AI Destekli İlaç Yönetimi Kamera ile ilaç kutularını okur (OCR), hatırlatıcı kurar ve etkileşimleri kontrol eder.

---

⚙️ Teknik Mimari

Katman Teknoloji
Frontend Flutter (Dart) – APK, IPA, EXE, Web
Sensörler sensors_plus, flutter_sound, camera
Veri Saklama Hive (NoSQL), SharedPreferences
AI/ML TensorFlow Lite (tflite_flutter), Google ML Kit
İletişim FlutterBluePlus (BLE), UsbSerial (USB)
Raporlama pdf, printing
Ses speech_to_text, flutter_tts
Ağ http (FHIR), url_launcher
Konum geolocator

📱 Platform Desteği: Android 5.0+, iOS 12+, Windows 10+, macOS (geliştirme), Web (kısmi).

---

🛠️ Kurulum ve Derleme

1. Projeyi Klonlayın

```bash
git clone https://github.com/ismailozdemir01/ish_tissuemap_fusion.git
cd ish_tissuemap_fusion
```

2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

3. (Opsiyonel) Python Test Motorunu Çalıştırın

```bash
cd python_demo
python3 main.py
```

4. Uygulamayı Derleyin

Platform Komut
Android APK flutter build apk --release
Windows EXE flutter build windows --release
iOS IPA flutter build ios --release (Xcode gerekli)
Web flutter build web --release

5. Cihazda Çalıştırın (Geliştirme)

```bash
flutter run
```

---

📱 Kullanım Kılavuzu

🔹 Bağlantı

· USB – Telefonu bilgisayara bağlayıp UsbSerial ile iletişim kurun.
· Bluetooth (BLE) – ISH markalı cihazları otomatik tarayın ve eşleştirin.

🔹 Tarama

1. AR Scan ekranını açın.
2. Telefonu vücudunuzda (karaciğer, mide, böbrek bölgeleri) yavaşça gezdirin.
3. Kırmızı nokta ve ısı haritası takip edecektir.
4. Taramayı Durdur & Kaydet ile Chronos'a kaydedin.

🔹 Raporlama

· PDF Rapor oluşturun ve paylaşın.
· FHIR ile doktorunuza gönderin.
· Acil Durum butonu ile konum ve skor içeren SOS mesajı atın.

🔹 Topluluk

· Sağlık hikayelerinizi paylaşın.
· Günlük meydan okumalara katılıp puan kazanın.

🔹 İlaç Yönetimi

· Kamera ile ilaç kutusunu okutun.
· Hatırlatıcı kurun ve etkileşim uyarılarını görün.

---

📂 Dosya Yapısı

```
lib/
├── core/               # Sabitler, tema, konfigürasyon
├── models/             # Veri modelleri
│   ├── tissue_point.dart
│   ├── chronos_snapshot.dart
│   ├── anomaly_report.dart
│   ├── health_tip.dart
│   ├── medication.dart
│   ├── community_post.dart
│   └── user_profile.dart
├── services/           # Servis katmanı
│   ├── sensor/         # Akustik, EMF, Spektral, Füzyon
│   ├── processing/     # MAC (Kalman)
│   ├── analysis/       # Chronos, Trend
│   ├── ai/             # Triage, Health Coach
│   ├── voice/          # Sesli Asistan
│   ├── medication/     # İlaç Yönetimi
│   ├── vision/         # Biyobelirteç
│   ├── fhir/           # FHIR Entegrasyonu
│   ├── emergency/      # SOS, Triyaj
│   ├── communication/  # USB, BLE
│   ├── export/         # PDF Rapor
│   ├── guidance/       # Haptic, TTS
│   └── storage/        # Hive veritabanı
├── screens/            # Ekranlar
│   ├── connection_screen.dart
│   ├── ar_scan_screen.dart
│   ├── timeline_screen.dart
│   ├── result_screen.dart
│   └── community/      # Topluluk ekranları
├── widgets/            # Özel widget'lar
│   ├── heatmap_painter.dart
│   ├── ar_overlay_painter.dart
│   └── connection_indicator.dart
└── main.dart           # Uygulama giriş noktası
```

---

🤝 Katkıda Bulunma

1. Bu projeyi fork edin.
2. Yeni bir branch oluşturun (feature/yeni-ozellik).
3. Değişikliklerinizi commit edin.
4. Branch'inizi push edin.
5. Bir Pull Request açın.

📌 Kod Stili: flutter format ve flutter analyze uygulayın.

---

🗺️ Yol Haritası (Roadmap)

✅ Sürüm 1.0 (Tamamlandı)

☑ Hibrit akustik + EMF tarama motoru
☑ MAC (Kalman Filtresi)
☑ Chronos Zaman Tüneli
☑ AR Rehberlik
☑ Spektral Doku Analizi
☑ AI Triyaj Asistanı
☑ PDF Rapor Üretici
☑ Sesli Asistan
☑ Sağlık Koçu
☑ İlaç Yönetimi
☑ Biyobelirteç Tespiti
☑ Sosyal Topluluk
☑ FHIR Entegrasyonu
☑ Acil Durum & Triyaj

🔜 Sürüm 2.0 (Planlanan)

□ Telehealth Entegrasyonu – Doktorla video görüşme
□ Blockchain Veri Güvenliği – Değiştirilemez sağlık kaydı
□ Çoklu Dil Desteği – TR, EN, DE, AR, RU
□ Wearable Entegrasyonu – Akıllı saatlerden veri okuma
□ Toplu Veri Analizi – Popülasyon sağlığı anonim analiz

---

📄 Lisans

Bu proje ISMAL OZDEMIR tarafından geliştirilmiştir. Tüm hakları saklıdır.
Ticari kullanım, izinsiz çoğaltma veya dağıtım yasaktır.
Detaylı lisans için LICENSE dosyasını inceleyin.

---

📬 İletişim

· Geliştirici: İsmail Özdemir
· E-posta: ismailozdemir@ish.com
· GitHub: ismailozdemir01
· Web: ish.com

---

🌟 ISH TissueMap Fusion – Sağlık teknolojisinde yeni bir çağ başlatıyor.
Herkesin cebinde bir sağlık asistanı.
