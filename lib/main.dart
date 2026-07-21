import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/game/infrastructure/services/audio_service.dart';
import 'features/progression/presentation/widgets/xp_gain_floating_text.dart';

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

class SehirBulmacaApp extends StatelessWidget {
  const SehirBulmacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Şehir Bulmaca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
