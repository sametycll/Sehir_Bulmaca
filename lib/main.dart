import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase yapılandırması tamamlandığında burası aktif edilecek
  /*
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  */

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
      title: 'Türkiye Şehir Bulmaca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Premium his için varsayılan Koyu Tema
      routerConfig: AppRouter.router,
    );
  }
}

