# Play Console — Mağaza Listesi (Taslak)

Uygulama adı (30 karakter): **Şehir Bulmacasi - Zeka Oyunu**  
Kısa açıklama (80 karakter): **Türkiye'nin 81 ilini haritada bul. Kombo yap, skor kır, liderlik tablosunda yüksel.**

## Uzun açıklama

Şehir Bulmaca ile Türkiye coğrafyasını eğlenceli bir yarışa dönüştür!

Harita üzerinde illeri bul, hızlı tahminlerle kombo yap ve skorunu yükselt. İster tüm Türkiye'yi bitir, ister bölge bölge oyna; zamana karşı veya blitz modlarıyla kendini zorla.

Özellikler:
• İnteraktif Türkiye haritası (81 il)
• 10 oyun modu: tüm Türkiye, zamana karşı, blitz ve 7 bölge
• Kombo sistemi ve ses efektleri
• XP, seviye ve başarımlar
• Günlük görevler ve streak
• Global liderlik tablosu
• Misafir veya Google ile giriş

Türkiye'yi ne kadar iyi biliyorsun? Hemen dene!

## Kategori önerisi
Oyun → Trivia / Eğitim / Arcade (en uygun olanı seçin)

## İletişim & politika
- Destek e-postası: [E-posta]
- Gizlilik politikası URL: [privacy_policy.html'i hosting'e yükledikten sonra URL]
- Geliştirici adı: Samet Yücel

## Data safety (özet)
| Veri türü | Toplanıyor mu? | Amaç |
|-----------|----------------|------|
| Ad / görünen ad | Evet (Google giriş) | Hesap, liderlik |
| E-posta | Evet (Google giriş) | Hesap |
| Kullanıcı kimlikleri | Evet | Auth, senkron |
| Oyun etkileşimi (skor, ilerleme) | Evet | Oyun işlevi |
| Cihaz kimliği | Evet | Misafir oturum |
| Reklam kimliği | Hayır | — |
| Konum | Hayır | — |

- Veriler satılmıyor
- Reklam için kullanılmıyor
- Şifreleme: transit (HTTPS / Firebase)

## Görseller (henüz üretilecek — Play Console gerekir)
- Uygulama ikonu: 512×512 (flutter_launcher_icons çıktısından)
- Feature graphic: 1024×500
- Telefon ekran görüntüleri: en az 2 (önerilen 4–8)
- 7" / 10" tablet (opsiyonel)

## Yayın adımları
1. `flutter build appbundle --release`
2. Play Console → Internal testing → AAB yükle
3. Gizlilik URL + Data safety doldur
4. Test et → Closed/Open → Production
