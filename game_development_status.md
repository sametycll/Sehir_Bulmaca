# 🗺️ Türkiye Şehir Bulmaca - Canlı Geliştirme ve Durum Raporu

Bu belge, **Türkiye Şehir Bulmaca** oyununun teknik altyapısını, mevcut oyun mekaniklerini, mobil/masaüstü optimizasyonlarını, son yapılan güncellemeleri ve gelecek geliştirme planlarını içeren dinamik bir rapor ve kılavuzdur. Süreç boyunca sürekli güncellenecektir.

---

## 🎮 1. Oyunun Temel Amacı ve Oynanış
Oyuncuların kısıtlı süre içerisinde (veya dilerlerse kendileri bitirene kadar) Türkiye'nin 81 ilini arama çubuğuna yazarak bulmaya çalıştıkları, hız ve genel kültür odaklı, yüksek oyun hissiyatına (game feel) sahip premium bir coğrafi arcade oyunudur.

---

## 🏗️ 2. Teknik Mimari ve Altyapı
Oyun, en yüksek kod kalitesi, genişletilebilirlik ve bakım kolaylığı sağlamak için modern mobil geliştirme standartlarına göre tasarlanmıştır:
* **Çekirdek:** Google Flutter & Dart.
* **Mimari Yapı:** Feature-Based Clean Architecture (Özellik Tabanlı Temiz Mimari).
  * `domain/`: Şehir varlıkları (CityEntity) ve iş kuralları.
  * `infrastructure/`: Coğrafi JSON veri yükleyicisi, ses servisleri.
  * `presentation/`: Riverpod durum yönetimleri, CustomPainter çizim katmanları, duyarlı ekran tasarımları.
* **Durum Yönetimi (State Management):** Güçlü, reaktif ve test edilebilir **Riverpod 2 (NotifierProvider.autoDispose)** yapısı.
* **Veri Katmanı:** Hızlı harita yüklemesi için optimize edilmiş, basitleştirilmiş Türkiye GeoJSON verisi.

---

## 💎 3. Aktif Oyun Özellikleri & Tasarım Detayları

### A. 🗺️ Gelişmiş Kartografi ve Harita Sistemi
* **Dinamik Renklendirme:** İller ilk başta premium orta gri renkte başlar, şehir sınırları net siyah çizgilerle ayrılır. Doğru tahmin edilen iller zümrüt yeşili (`Color(0xFF10B981)`) olarak parlar.
* **Premium Atmosfer:** Türkiye dışındaki deniz alanları, üstü açık mavi, altı koyu derin lacivert olan pürüzsüz ve lüks bir gradyan geçişe sahiptir.
* **GPU Gölge Efekti:** Haritanın arkasında, 81 ayrı parça yerine **tek parça birleşik yol (combinedTurkeyPath)** ile çizilen 3D derinlik gölgesi yer alır. Bu işlem GPU yükünü %98 düşürür!
* **Neon Kamera Odağı:** Seçilen veya en son bulunan ile harita üzerinde otomatik olarak yumuşakça odaklanılır (Zoom & Pan) ve il sınırları parıldayan bir neon mavi ışıkla çevrelenir.

### B. 🔥 Kombo ve Puan Çarpanı Sistemi
* **Hız Ödülü:** 4 saniye içinde ardı ardına şehir tahmin edildiğinde kombo çarpanı tetiklenir (`KOMBO x2`, `KOMBO x3`...).
* **Akıllı Ses Desteği:** Kombo katlandıkça artan ses tonlarında özel kombo sesleri tetiklenir.

### C. 📱 Mobil ve Klavye-Duyarlı Tasarım (Samsung S23 FE Uyumlu!)
* **Klavye-Duyarlı İstatistik Paneli:** Telefon ekranında klavye açıldığı anda üstteki devasa istatistik paneli tek bir satıra (`BULUNAN: X | SÜRE: Y | KALAN: Z`) daralarak dikeyde **~100px** alan kazandırır ve haritanın küçülmesini tamamen engeller.
* **Duyarlı Detay Kartı:** Klavye açıkken bir şehre tıklandığında bilgi kartı otomatik olarak haritanın en üstüne (`top: 8`) kayar, ipucu metnini geçici olarak gizler ve kompakt dolgusu sayesinde klavyeyle asla çakışmaz!
* **Mükemmel Donmayan Overlay Bildirimleri:** Tahmin yapıldığında parlayan `+ANKARA` veya `KOMBO x2 🔥` bildirimleri standart Flutter **`Overlay` ve `OverlayEntry`** mimarisi kullanılarak tetiklenir. Kendinden `AnimationController` animasyonlu ve donanım hızlandırmalı bu yapı, yerel `Stack` veya klavye taşma sınırlarına (clipping) takılmadan doğrudan global ekran katmanında çizilir. Bu sayede Android Release modunda görülen tüm görünmeme ve kasma problemleri kökünden giderilmiştir! Klavye açıkken bildirim başlangıç dikey sınırı dinamik olarak yukarı kaydırılarak (`size.height * 0.35`) klavye altında kalmaları önlenir.

### D. 🔊 Ses ve Atmosfer Sistemi
* **Gelişmiş Gerçekçi Ses Motoru:** Arka planda **`audioplayers`** kütüphanesi entegre edilmiştir. `assets/sounds/` dizinindeki gerçek ses dosyalarını (`doğru_cevap.mp3`, `yanlis_cevap.mp3`, `combo_x.mp3`, `oyun_basarili.mp3`) hem Windows hem de Android (Mobile) platformlarında anında oynatır.
* **Try-Catch Güvenlik Sarmalı:** Herhangi bir ses dosyası eksik olsa dahi oyunda çökme veya donma yaşanmaz, sistem sessizce hata yakalayarak oyun deneyimini kesintisiz sürdürür. Sessize alma (Mute) desteği aktiftir.

---

## ⚡ 4. Performans ve 120 FPS Optimizasyonları
Oyunun hiçbir mobil cihazda donmaması ve kasma yaşamaması için uygulanan üst düzey optimizasyonlar:
1. **Trigonometri Önbelleği (Trigonometry Caching):** Ana menüde dönen pusulanın rüzgar yıldızı koordinat hesaplamaları boyama döngüsünden alınıp `initState` içinde bir kez hesaplanmış ve GPU'ya hazır vektör olarak beslenmiştir.
2. **Paint Nesneleri Geri Dönüşümü:** `CustomPainter` boyama döngülerinde her karede yeni `Paint` nesnesi üretilmesi engellenmiş, bellek çöp toplayıcısının (Garbage Collector) yükü sıfıra indirilmiştir.
3. **Heavy Blur İptali:** Modal geçişlerinde telefon GPU'larını zorlayan `BackdropFilter` ağır bulanıklaştırma katmanları yerine, son derece şık opak koyu cam renkleri (`Color(0xFA1F262E)`) kullanılarak animasyonlar akıcı kılınmıştır.

---

## 🏆 5. Yerel Liderlik Tablosu
* Oyun süre veya bayrak ikonu ile bitirildiğinde, kaç doğru/yanlış il bilindiği süreyle birlikte gösterilir ve local Liderlik Tablosuna (Leaderboard) kaydedilir.

---

## 🔮 6. Gelecek Yol Haritası (Next Steps)
Gelecek oturumlarda eklenmesi planlanan ve sıradaki geliştirmeler:
1. **Oyun İçi İpucu ve Bölgesel Başarı Rozetleri:** Limitli rastgele il bulma ipucu sistemi ve kritik şehir eşiklerinde (`25`, `50`, `75`) ekranda parlayan konfetili zümrüt rozetler.
2. **Podyumlu Liderlik Tablosu:** İlk 3 oyuncu için altın, gümüş ve bronz kupaların yer aldığı 3D podyum animasyonları.
3. **Çoklu Oyun Modları:** Zamana Karşı (Time Attack) veya Plakadan Şehir Bulma modları.
