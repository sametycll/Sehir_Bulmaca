import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static bool _muted = false;

  // Çöp toplayıcıdan (GC) etkilenmeyen kalıcı oynatıcı kanalları
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static final AudioPlayer _comboPlayer = AudioPlayer();
  static final AudioPlayer _successPlayer = AudioPlayer();

  static void toggleMute() {
    _muted = !_muted;
    developer.log('Ses durumu: ${_muted ? "Sessiz" : "Ses Açık"}');
  }

  static bool get isMuted => _muted;

  /// Doğru tahmin sesi (Her şehir bulunduğunda stop-play ile anında sıfırlanıp tekrar çalar!)
  static Future<void> playCorrect() async {
    if (_muted) return;
    try {
      await _correctPlayer.stop();
      await _correctPlayer.play(AssetSource('sounds/doğru_cevap.mp3'));
    } catch (e) {
      developer.log('🔊 [AudioService] Doğru ses çalma hatası: $e');
    }
  }

  /// Yanlış tahmin sesi (Dosya yoksa hata vermez, sessizce es geçer)
  static Future<void> playWrong() async {
    if (_muted) return;
    try {
      await _wrongPlayer.stop();
      await _wrongPlayer.play(AssetSource('sounds/yanlis_cevap.mp3')).catchError((error) {
        developer.log('🔊 [AudioService] Yanlış cevap ses dosyası yok, sessizce es geçiliyor.');
      });
    } catch (e) {
      developer.log('🔊 [AudioService] Yanlış ses çalma hatası: $e');
    }
  }

  /// Kombo serisi sesi (Eğer kombo sesi telefonda yoksa, otomatik olarak varsayılan doğru tahmin sesini çalar!)
  static Future<void> playCombo(int comboCount) async {
    if (_muted) return;
    try {
      await _comboPlayer.stop();
      await _comboPlayer.play(AssetSource('sounds/combo_1.mp3')).catchError((error) {
        developer.log('🔊 [AudioService] combo_$comboCount.mp3 bulunamadı. Doğru tahmin sesine dönülüyor...');
        playCorrect();
      });
    } catch (e) {
      developer.log('🔊 [AudioService] Kombo ses çalma hatası: $e');
      playCorrect();
    }
  }

  /// Oyun başarıyla bitirildiğinde zafer sesi (Dosya yoksa varsayılan doğru tahmin sesine döner)
  static Future<void> playSuccess() async {
    if (_muted) return;
    try {
      await _successPlayer.stop();
      await _successPlayer.play(AssetSource('sounds/oyun_basarili.mp3')).catchError((error) {
        developer.log('🔊 [AudioService] Zafer ses dosyası yok. Doğru tahmin sesine dönülüyor...');
        playCorrect();
      });
    } catch (e) {
      developer.log('🔊 [AudioService] Zafer ses çalma hatası: $e');
      playCorrect();
    }
  }
}
