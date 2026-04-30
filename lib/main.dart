import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/app_splash_screen.dart';
import 'screens/main_hub.dart';
import 'screens/auth_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/legal_consent_screen.dart';
import 'firebase_options.dart';
import 'services/theme_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/review_service.dart';
import 'services/network_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar AdMob
  unawaited(MobileAds.instance.initialize());
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Firebase App Check para Segurança
  /*
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    print("AppCheck init error: $e");
  }
  */

  // Inicializar Tema e Preferências
  await ThemeService.init();

  // Inicializar Notificações
  await NotificationService.init();

  // Inicializar Google Sign In v7.0.0+
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: '103657070291-r8ptgah7o2o4g43fkpb1ishops0utghp.apps.googleusercontent.com',
    );
  } catch (e) {
    print("GoogleSignIn init error: $e");
  }
  // Verificar se é hora de pedir avaliação (estrelas)
  unawaited(ReviewService.checkAndRequestReview());
  
  runApp(const MeuCozinheiroApp());
}

class MeuCozinheiroApp extends StatelessWidget {
  const MeuCozinheiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Meu Cozinheiro',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          // TEMA CLARO
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD2691E),
              primary: const Color(0xFFB33E24),
              secondary: const Color(0xFF5D8A66),
              surface: const Color(0xFFFAF7F2),
              onSurface: const Color(0xFF262321),
            ),
            scaffoldBackgroundColor: Colors.white,
            textTheme: _textTheme(ThemeData.light().textTheme, const Color(0xFF262321)),
            appBarTheme: _appBarTheme(const Color(0xFFFAF7F2), const Color(0xFF262321)),
            elevatedButtonTheme: _buttonTheme(),
            outlinedButtonTheme: _outlinedButtonTheme(),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          // TEMA ESCURO
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFFC84C2C),
              primary: const Color(0xFFE66A4E),
              secondary: const Color(0xFF7CAF89),
              surface: const Color(0xFF1A1715),
              onSurface: const Color(0xFFEDE8E5),
            ),
            scaffoldBackgroundColor: const Color(0xFF12100F),
            textTheme: _textTheme(ThemeData.dark().textTheme, const Color(0xFFEDE8E5)),
            appBarTheme: _appBarTheme(const Color(0xFF1A1715), const Color(0xFFEDE8E5)),
            elevatedButtonTheme: _buttonTheme(),
            outlinedButtonTheme: _outlinedButtonTheme(),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1A1715),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          
          home: const NetworkWrapper(child: AppSplashScreen()),
        );
      },
    );
  }

  TextTheme _textTheme(TextTheme base, Color textColor) {
    return GoogleFonts.interTextTheme(
      base.copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        displaySmall: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
        headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 24, color: textColor),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20, color: textColor),
      ),
    );
  }

  AppBarTheme _appBarTheme(Color bgColor, Color textColor) {
    return AppBarTheme(
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textColor),
    );
  }

  ElevatedButtonThemeData _buttonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC84C2C),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        if (!user.emailVerified && user.providerData.any((p) => p.providerId == 'password')) {
          return const VerifyEmailScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              if (!userData.containsKey('age') || userData['age'] == 0) {
                return const CompleteProfileScreen();
              }
              
              // 1. Verificar se já viu o onboarding
              final onboardingSeen = userData['onboardingSeen'] ?? false;
              if (!onboardingSeen) {
                return _OnboardingGate(userId: user.uid);
              }
              
              // 2. Verificar se já aceitou os termos legais
              final legalAccepted = userData['legalAccepted'] ?? false;
              if (!legalAccepted) {
                return _LegalGate(userId: user.uid);
              }
              
              return const MainHub();
            }
            return const CompleteProfileScreen();
          },
        );
      },
    );
  }
}

class _LegalGate extends StatelessWidget {
  final String userId;
  const _LegalGate({required this.userId});

  @override
  Widget build(BuildContext context) {
    return LegalConsentScreen(
      onAccepted: () async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'legalAccepted': true});
      },
    );
  }
}

class _OnboardingGate extends StatelessWidget {
  final String userId;
  const _OnboardingGate({required this.userId});

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onComplete: () async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'onboardingSeen': true});
      },
    );
  }
}
