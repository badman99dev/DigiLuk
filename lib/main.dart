import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/error.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/onboarding/screens/onboarding_screen.dart';
import 'package:digiluk/mobile_layout_screen.dart';
import 'package:digiluk/router.dart';
import 'package:digiluk/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase init might fail with placeholder config - continue anyway
    debugPrint('Firebase init warning: $e');
  }
  runApp(
    const ProviderScope(
      child: DigiLukApp(),
    ),
  );
}

class DigiLukApp extends ConsumerStatefulWidget {
  const DigiLukApp({super.key});

  @override
  ConsumerState<DigiLukApp> createState() => _DigiLukAppState();
}

class _DigiLukAppState extends ConsumerState<DigiLukApp> {
  bool _showOnboarding = true;

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataAuthProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DigiLuk',
      theme: ThemeData(
        primaryColor: digilukPrimary,
        scaffoldBackgroundColor: digilukBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: digilukPrimary,
          primary: digilukPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: digilukPrimary,
          foregroundColor: digilukWhite,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: digilukCardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: digilukDividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: digilukDividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: digilukPrimary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: digilukPrimary,
            foregroundColor: digilukWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: userAsync.when(
        data: (user) {
          if (user == null) {
            return OnboardingScreen(onComplete: _completeOnboarding);
          }
          return const MobileLayoutScreen();
        },
        error: (err, trace) {
          debugPrint('Auth check error: $err');
          return OnboardingScreen(onComplete: _completeOnboarding);
        },
        loading: () => const Scaffold(body: Loader()),
      ),
    );
  }
}
