import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "features/auth/otp_login_screen.dart";

void main() {
  runApp(const ProviderScope(child: MeyahApp()));
}

class MeyahApp extends StatelessWidget {
  const MeyahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "مياه Meyah",
      debugShowCheckedModeBanner: false,
      locale: const Locale("ar", "SA"),
      supportedLocales: const [
        Locale("ar", "SA"),
        Locale("en", "US"),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primaryColor: const Color(0xFF1A438A),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        textTheme: GoogleFonts.cairoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A438A),
          primary: const Color(0xFF1A438A),
        ),
        useMaterial3: true,
      ),
      home: const OtpLoginScreen(),
    );
  }
}
