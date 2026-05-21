import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/game/infrastructure/services/audio_service.dart';
import 'features/game/presentation/providers/game_notifier.dart';
import 'features/progression/presentation/widgets/xp_gain_floating_text.dart';
import 'features/progression/presentation/providers/level_up_queue_provider.dart';
import 'features/progression/presentation/widgets/level_up_overlay_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ses dosyalarını önceden doğrula; eksik olanlar için oynatma yapılmaz
  await AudioService.verifyAssets();

  // Uçan XP yazı overlay servisini kaydet
  XpFloatingOverlayServiceImpl.registerService();

  runApp(
    const ProviderScope(
      child: SehirBulmacaApp(),
    ),
  );
}

class SehirBulmacaApp extends ConsumerWidget {
  const SehirBulmacaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seviye atlama popuplarını kuyruktan sırayla çeken global dinleyici
    ref.listen<List<LevelUpDetails>>(levelUpQueueProvider, (previous, next) {
      if (next.isNotEmpty) {
        // Eğer oyun devam ediyorsa popupları gösterme, oyun sonunu bekle
        final gameState = ref.read(gameProvider);
        if (gameState.isRunning) {
          return;
        }

        final notifier = ref.read(levelUpQueueProvider.notifier);
        if (!notifier.isShowing) {
          notifier.markAsShowing();
          _showLevelUpOverlay(next.first, ref);
        }
      }
    });

    return MaterialApp.router(
      title: 'Türkiye Şehir Bulmaca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Premium his için varsayılan Koyu Tema
      routerConfig: AppRouter.router,
    );
  }

  void _showLevelUpOverlay(LevelUpDetails details, WidgetRef ref) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) {
      // Eğer navigasyon context'i henüz hazır değilse bir sonraki frame'de dene
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLevelUpOverlay(details, ref);
      });
      return;
    }

    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = createLevelUpOverlayEntry(
      details: details,
      onFinished: () {
        // Tamam butonuna tıklanınca listeden çıkar ve sıradakini kontrol et
        ref.read(levelUpQueueProvider.notifier).dequeue();
        final remaining = ref.read(levelUpQueueProvider);
        if (remaining.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(levelUpQueueProvider.notifier).markAsShowing();
            _showLevelUpOverlay(remaining.first, ref);
          });
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        overlayState.insert(entry);
      }
    });
  }
}

