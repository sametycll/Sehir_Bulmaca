import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static bool _muted = false;

  // Windows'ta AudioPlayer nesnelerini hiç oluşturmuyoruz —
  // oluşturulmaları bile geçersiz file:/// URI üretiyor.
  static bool get _isSupported {
    if (kIsWeb) return true;
    try {
      return !Platform.isWindows;
    } catch (_) {
      return true;
    }
  }

  // Lazy-initialized oynatıcılar — sadece desteklenen platformlarda oluşturulur
  static AudioPlayer? _correctPlayer;
  static AudioPlayer? _wrongPlayer;
  static AudioPlayer? _comboPlayer;
  static AudioPlayer? _successPlayer;
  static AudioPlayer? _heartbeatPlayer;

  static final Set<String> _verifiedAssets = {};
  static bool _assetsVerified = false;

  static void toggleMute() {
    _muted = !_muted;
    developer.log('Ses durumu: ${_muted ? "Sessiz" : "Ses Açık"}');
  }

  static bool get isMuted => _muted;

  static Future<void> verifyAssets() async {
    if (_assetsVerified) return;
    if (!_isSupported) {
      developer.log('🔇 [AudioService] Windows — ses devre dışı.');
      _assetsVerified = true;
      return;
    }

    // Oynatıcıları sadece şimdi ve sadece desteklenen platformda oluştur
    _correctPlayer ??= AudioPlayer();
    _wrongPlayer ??= AudioPlayer();
    _comboPlayer ??= AudioPlayer();
    _successPlayer ??= AudioPlayer();
    _heartbeatPlayer ??= AudioPlayer();

    final candidates = [
      'sounds/doğru_cevap.mp3',
      'sounds/yanlis_cevap.mp3',
      'sounds/combo_1.mp3',
      'sounds/oyun_basarili.mp3',
      'sounds/heartbeat.mp3',
    ];
    for (final path in candidates) {
      try {
        await rootBundle.load('assets/$path');
        _verifiedAssets.add(path);
      } catch (_) {
        developer.log('🔊 [AudioService] ⚠️ Asset eksik: $path');
      }
    }
    _assetsVerified = true;
  }

  static Future<void> _safePlay(AudioPlayer? player, String assetPath) async {
    if (_muted || !_isSupported || player == null) return;
    if (!_assetsVerified) await verifyAssets();
    if (!_verifiedAssets.contains(assetPath)) return;
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (e) {
      developer.log('🔊 [AudioService] Ses hatası ($assetPath): $e');
    }
  }

  static Future<void> playCorrect() async {
    await _safePlay(_correctPlayer, 'sounds/doğru_cevap.mp3');
  }

  static Future<void> playWrong() async {
    await _safePlay(_wrongPlayer, 'sounds/yanlis_cevap.mp3');
  }

  static Future<void> playCombo(int comboCount) async {
    if (_verifiedAssets.contains('sounds/combo_1.mp3')) {
      await _safePlay(_comboPlayer, 'sounds/combo_1.mp3');
    } else {
      await playCorrect();
    }
  }

  static Future<void> playSuccess() async {
    if (_verifiedAssets.contains('sounds/oyun_basarili.mp3')) {
      await _safePlay(_successPlayer, 'sounds/oyun_basarili.mp3');
    } else {
      await playCorrect();
    }
  }

  static Future<void> playHeartbeat() async {
    await _safePlay(_heartbeatPlayer, 'sounds/heartbeat.mp3');
  }
}
