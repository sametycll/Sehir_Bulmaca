# Yayın Kontrol Listesi — Şehir Bulmaca

## Tamamlanan (repo)
- [x] Upload keystore (`android/app/upload-keystore.jks`) + `key.properties`
- [x] Release signing config (`android/app/build.gradle.kts`)
- [x] Uygulama adı: Şehir Bulmaca
- [x] Launcher ikonu (branding)
- [x] Gizlilik politikası taslağı (`store/`)
- [x] Firestore kuralları: achievements / progression / daily
- [x] Play listing metin taslağı

## Senin yapman gerekenler
- [ ] `android/keystore_credentials.txt` dosyasını **çevrimdışı yedekle** (şifreler + keystore)
- [ ] Firebase Console → Project settings → Android app → **SHA-1 ekle** (aşağıdaki değer)
- [ ] `firestore.rules` dosyasını Firebase'e deploy et
- [ ] `store/privacy_policy.html` içindeki e-postayı doldur ve bir URL'de yayınla (GitHub Pages / Netlify / kendi siten)
- [ ] Play Console Data safety formunu doldur
- [ ] Ekran görüntüleri + feature graphic ekle
- [ ] Internal testing ile AAB yükle

## Release SHA (Google Sign-In için Firebase'e ekle)

```
SHA-1: DE:80:08:35:4A:C0:F7:5C:81:C4:D7:B0:66:7F:B2:63:BD:E5:22:61
SHA-256: D0:1A:01:48:EE:08:4A:2C:65:D7:84:9C:E7:21:2F:71:83:75:F7:0F:E5:72:E9:4E:6B:C2:1E:83:0A:5F:B2:68
```

Firebase: https://console.firebase.google.com/project/sehir-bulmaca/settings/general

## Firestore rules deploy

```bash
firebase deploy --only firestore:rules
```

(`firebase.json` içinde firestore rules yolu tanımlı olmalı.)

## Release AAB

```bash
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`
