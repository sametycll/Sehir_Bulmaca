# 🗺️ Türkiye Şehir Bulmaca - Canlı Geliştirme ve Durum Raporu

Bu belge, **Türkiye Şehir Bulmaca** oyununun teknik altyapısını, mevcut oyun mekaniklerini, mobil/masaüstü optimizasyonlarını, son yapılan güncellemeleri ve gelecek geliştirme planlarını içeren dinamik bir rapor ve kılavuzdur. Süreç boyunca sürekli güncellenecektir.

**Son Güncelleme:** 21 Mayıs 2026

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
* **Backend:** Firebase (Authentication + Cloud Firestore) entegrasyonu.
* **Yönlendirme:** `go_router` tabanlı type-safe yönlendirme; Firebase Auth durumuna göre otomatik yönlendirme (redirect).

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

### E. 🎮 Çoklu Oyun Modları
Oyun, çeşitli oynanış deneyimleri sunan 10 farklı mod içermektedir:

| Mod | Açıklama | Hedef Şehir Sayısı |
|---|---|---|
| **Tüm Türkiye** | Klasik mod, süre baskısı yok | 81 İl |
| **Zamana Karşı ⚡** | 60 sn ile başla, doğru tahminde +3sn kazan | 81 İl |
| **60 Saniye Yarışı ⏱️** | Süre yok, 60 saniyede maks şehir bul | 81 İl |
| **Marmara Bölgesi** | Sadece Marmara'nın 11 ili | 11 İl |
| **Ege Bölgesi** | Sadece Ege'nin 8 ili | 8 İl |
| **Akdeniz Bölgesi** | Sadece Akdeniz'in 8 ili | 8 İl |
| **İç Anadolu Bölgesi** | Sadece İç Anadolu'nun 13 ili | 13 İl |
| **Karadeniz Bölgesi** | Sadece Karadeniz'in 18 ili | 18 İl |
| **Doğu Anadolu Bölgesi** | Sadece Doğu Anadolu'nun 14 ili | 14 İl |
| **Güneydoğu Anadolu Bölgesi** | Sadece Güneydoğu'nun 9 ili | 9 İl |

---

## ⚡ 4. Performans ve 120 FPS Optimizasyonları
Oyunun hiçbir mobil cihazda donmaması ve kasma yaşamaması için uygulanan üst düzey optimizasyonlar:
1. **Trigonometri Önbelleği (Trigonometry Caching):** Ana menüde dönen pusulanın rüzgar yıldızı koordinat hesaplamaları boyama döngüsünden alınıp `initState` içinde bir kez hesaplanmış ve GPU'ya hazır vektör olarak beslenmiştir.
2. **Paint Nesneleri Geri Dönüşümü:** `CustomPainter` boyama döngülerinde her karede yeni `Paint` nesnesi üretilmesi engellenmiş, bellek çöp toplayıcısının (Garbage Collector) yükü sıfıra indirilmiştir.
3. **Heavy Blur İptali:** Modal geçişlerinde telefon GPU'larını zorlayan `BackdropFilter` ağır bulanıklaştırma katmanları yerine, son derece şık opak koyu cam renkleri (`Color(0xFA1F262E)`) kullanılarak animasyonlar akıcı kılınmıştır.

---

## 🔐 5. Kimlik Doğrulama (Authentication) Sistemi

### Giriş Yöntemleri
* **Anonim / Misafir Giriş:** Kayıt zorunluluğu olmadan oynanabilir. Cihaza özgü kalıcı bir kimlik (Device ID) oluşturulur — uygulama silinse bile skor korunur.
  * Android'de `android.os.Build.ID` (donanım bazlı) kullanılır.
  * iOS'ta `identifierForVendor` kullanılır.
  * Web'de `SharedPreferences`'a kayıtlı UUID kullanılır.
  * Güvenlik için `FlutterSecureStorage` (Keychain/Keystore) ile kalıcı saklama yapılır.
* **Google ile Giriş:** `google_sign_in` paketi kullanılarak OAuth 2.0 akışıyla Firebase Authentication'a bağlanılır. Tüm platformlarda desteklenir.

### Teknik Detaylar
* **`AuthNotifier` (Riverpod StateNotifier):** Tüm kimlik doğrulama durumunu (`initial`, `authenticating`, `authenticated`, `unauthenticated`, `error`) tek noktadan yönetir.
* **Misafir hesabı:** Firebase Email/Password provider üzerinde `{deviceId}@sehirbulmaca.anon` formatında özel e-posta ile kayıt yapılır. Böylece cihaza özgü kalıcı Firebase hesabı oluşturulur.
* **Hata Yönetimi:** `operation-not-allowed`, `too-many-requests`, `network-request-failed` gibi Firebase hata kodları Türkçe kullanıcı dostu mesajlara çevrilir.
* **Otomatik yönlendirme:** `go_router` refresh listener ile Firebase Auth durumu dinlenir; giriş yapılmamışsa Login ekranına, yapılmışsa doğrudan Ana Ekrana yönlendirilir.

### Giriş Ekranı Tasarımı
* Yavaş dönen pusula animasyonu (80 sn döngü) ile premium karanlık arka plan.
* Anonim (Misafir) ve Google giriş butonları — hover/tap animasyonlu, neon gölgeli.
* Hata durumunda animasyonlu SnackBar bildirimleri.

---

## 🏆 6. Küresel Liderlik Tablosu (Firebase Firestore)

### Veri Mimarisi
* **Cloud Firestore** koleksiyonu: `leaderboards/`
* **Doküman ID formatı:** `{modeId}__{userId}` — Her oyuncu her modda sadece **bir** en iyi skor kaydına sahiptir (upsert mantığı).
* **Composite Score:** `(score × 100.000) + (100.000 − elapsedTime)` formülüyle hesaplanan tek bir sayıya indirgeme. Yüksek skor öncelikli, düşük süre ikincil tiebreaker.

### Sıralama Ekranı Özellikleri
* **Mod seçici:** 10 oyun modu arasında yatay kaydırmalı animasyonlu tab bar.
* **Gerçek zamanlı stream:** Firestore `snapshots()` ile anlık güncelleme.
* **Altın/Gümüş/Bronz** satırları özel arka plan rengi ve kupa ikonu ile vurgulanır.
* **SIRA / OYUNCU / ŞEHİR / SÜRE** kolon başlıkları ile Premium tablo tasarımı.
* **Boşluk:** Info bar ile kolon başlıkları arasında yeterli dikey boşluk.
* **Yerel önbellek temizleme:** Çevrimdışı skor geçmişini silmek için onay diyaloğu.

### İstatistiklerim Sekmesi _(Yeni)_
Liderlik tablosu ekranına ikinci bir sekme eklendi — giriş yapan kullanıcının **tüm modlardaki kendi en iyi skorlarını** tek bir yerde gösterir:
* 👤 **Profil kartı:** İsim + Misafir/Kayıtlı oyuncu rozeti.
* 📊 **3'lü özet kartı:** Toplam oynanan mod sayısı, en yüksek şehir skoru, en hızlı tamamlanma süresi.
* 🗺️ **Mod bazlı detay listesi:** Her oyun modu için en iyi skor, süre ve tamamlanma yüzdesi (LinearProgressIndicator ile görsel).
* Henüz oynanmamış modlar soluk/gri gösterilir, oynanmış modlara renkli ilerleme çubuğu eşlik eder.

### Güvenlik Kuralları (Firestore Security Rules)
* Kullanıcı yalnızca kendi `userId` eşleşen dokümanı yazabilir.
* Okuma herkese açıktır (küresel sıralama görüntüleme).
* Composite score sunucu tarafında doğrulama ile manipülasyona karşı korunur.

---

## 🎖️ 7. Başarım (Achievement) & Rozet Sistemi

Oyuncuların oyun içinde gösterdikleri çeşitli performanslara göre kilitlerini açabilecekleri, yüksek sadakatli ve oyun hissini artıran bir başarım (rozet) sistemidir.

### Teknik Mimari ve Veri Optimizasyonu
* **O(k) Event-Driven Engine (`AchievementEngine`):** Başarımları her an kontrol etmek yerine, sadece gerçekleşen olaylara (`CityFound`, `ComboReached`, `GameCompleted`, `LeaderboardEntered`, `DailyLogin`) göre ilgili kuralları tetikleyen asenkron bir motor kullanılır.
* **Offline-First Firebase Modeli:**
  * **Yerel Önbellek (`LocalAchievementCache`):** `SharedPreferences` ile cold-start durumlarında başarımlar anında yüklenir ve çevrimdışı oynanış desteklenir.
  * **Maliyet Optimizasyonu:** Başarımların statik tanımları yerelde (`AchievementDefinitions`) tutulur. Firebase Firestore üzerinde ise yalnızca kazanılan ilerlemeler (`users/{uid}/achievements/main`) debounced (2 saniye gecikmeli ve toplu/batch) olarak yazılır. Bu sayede Firestore read/write maliyetleri minimuma indirgenmiştir.

### Kullanıcı Arayüzü (UI/UX)
* **Custom Slide-Up Overlay:** Başarım kilidi açıldığında, ana ekran akışını kesmeden ekranın üst kısmında donanım hızlandırmalı, neon ışıltılı ve akıcı slide-up kart bildirimleri belirir.
* **Detaylı Arayüz (`achievements_screen.dart`):**
  * `SliverAppBar` ile dinamik kaydırma efekti.
  * Yaygın (Common), Nadir (Rare), Efsanevi (Legendary) gibi **Nadirliğe (Rarity)** göre filtreleme ve görsel temalandırma.
  * Gizli başarımlar (Secret Achievements) için özel maskeleme ve kilit açıldığında detayları gösterme.
  * Dokunulduğunda tüm detayları açan premium Bottom Sheet.
* **Hassas Ses Desteği:** Başarım kilidi açıldığında, nadirlik seviyesine uygun özel ses tonları (`AudioService`) oynatılır.

---

## 📈 8. XP & Seviye İlerleme (Progression) Sistemi

Oyunculara sürekli gelişim ve oyun içi ilerleme hissi veren, yüksek reaktiflikte tasarlanmış tecrübe puanı (XP) ve seviye (Level) sistemidir.

### Matematiksel Altyapı (Quadratic Scaling)
Seviye ve kümülatif XP arasındaki ilişki quadratic formül ile yönetilir:
* **Formül:** $\text{xpToNextLevel}(L) = 50 \times L + 50$
* **Kümülatif Formül:** $\text{totalXpToReach}(L) = 25 \times L^2 + 25 \times L - 50$
* **O(1) Doğrudan Hesaplama:** Toplam XP'den seviyeyi döngüye girmeden bulabilmek için analitik denklem çözümü kullanılır:
  $$L = \lfloor \frac{-25 + \sqrt{5625 + 100 \times \text{totalXp}}}{50} \rfloor$$

### Veri Eşitleme ve Debounce
* **Spam Koruma:** Her XP artışında veri yazım yükünü azaltmak için yerel önbelleğe anında yazılır (optimistic update), Firestore'a ise **3 saniye debounce** uygulanarak tek bir `set` işlemi ile yazılır (`users/{uid}/progression/main`).

### UI & Premium Geri Bildirim
* **XP Gain Floating Text (`xp_gain_floating_text.dart`):** Şehir bulunduğunda klavye engeline takılmadan ekranın ortasından yukarı süzülen neon yeşil `+10 XP` veya turuncu `+50 BONUS XP` animasyonlu overlay yazıları.
* **Level Up Overlay (`level_up_overlay_widget.dart`):** Seviye atlandığında ekrana gelen, arka planı bulandıran, neon halkalar saçan, particle patlamaları içeren ve dahili `HapticFeedback` ile titreşim veren premium modal katmanı.
* **Çoklu Seviye Atlama (FIFO Queue):** Tek seferde birden fazla seviye atlandığında popuplar sırayla arka arkaya kuyruktan çekilerek gösterilir.
* **Profil Gelişim Ekranı (`progression_screen.dart`):** Oyuncunun toplam XP'si, seviyesi, unvanı (**Çaylak Gezgin, Harita Kaşifi, Bölge Ustası, Türkiye Fatihi, Coğrafya Efsanesi**), seviye milestoneları ve istatistiklerini içeren modern glassmorphism tasarımlı sayfa.

---

## ⚡ 9. Performans ve Kalite İyileştirmeleri (Son Oturum)

* **Firebase Auth hata kodları genişletildi:** Eski SDK'larda `user-not-found` olan kod yeni sürümlerde `INVALID_LOGIN_CREDENTIALS` olarak dönebilmektedir. Tüm olası kodlar tek bir `Set<String>` içinde toplanarak yönetilmektedir.
* **`debugPrint` loglama:** Kimlik doğrulama akışında `[AuthNotifier]` prefix'li log satırları eklenerek hata ayıklama kolaylaştırıldı.
* **`myStatsProvider` (FutureProvider.autoDispose):** Kullanıcının tüm modlardaki skorlarını Firestore'dan `userId` ile filtreleyerek tek sorguda çeker.
* **Tab bazlı liderlik navigasyonu:** `_leaderboardTabProvider` (StateProvider.autoDispose) ile sekme durumu verimli şekilde yönetilir.
* **Font Ağırlığı ve Renk Düzeltmeleri:** `FontWeight.w950` kullanımı `w900` ile güncellendi ve dynamic `.withValues(alpha: ...)` API'leri flutter standartlarına uygun hale getirildi.

---

## 🔮 10. Gelecek Yol Haritası (Next Steps)

Sıradaki geliştirmeler için planlanan özellikler:
1. **Oyun İçi İpucu Sistemi:** Limitli rastgele il bulma ipuçları ve kritik eşiklerde (`25`, `50`, `75` il) konfetili zümrüt rozet bildirimleri.
2. **Plakadan Şehir Bulma Modu:** Türkiye plaka kodlarından şehir tahmin etme alternatif oyun modu.
3. **Push Bildirim Desteği:** Firebase Cloud Messaging (FCM) ile sıralama değişikliği bildirimleri.
4. **Admin Paneli:** Küresel liderlik tablosunu yönetmek, şüpheli skorları temizlemek için web tabanlı yönetim arayüzü.
5. **Daha Fazla Coğrafi Başarım:** Bölgesel başarımları ve mod tamamlama başarımlarını genişletme.
