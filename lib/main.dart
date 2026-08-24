import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared/widgets/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw edge-to-edge behind the system status/navigation bars instead of
  // leaving a mismatched system-colored strip at the top and bottom.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: MySpendingsApp()));
}

/// Brand colors — a dark ground with a gold accent, deliberately not the
/// ubiquitous teal-gradient "fintech app" look.
const _bg = Color(0xFF14161B);
const _surface = Color(0xFF1B1E25);
const _surfaceHigh = Color(0xFF23262F);
const _gold = Color(0xFFE0B152);
const _ink = Color(0xFFF2F0EA);

class MySpendingsApp extends StatelessWidget {
  const MySpendingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.dark,
      surface: _surface,
      onSurface: _ink,
      surfaceContainerHigh: _surfaceHigh,
      surfaceContainerHighest: _surfaceHigh,
      primary: _gold,
      onPrimary: const Color(0xFF241B04),
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return MaterialApp(
      title: 'My Spendings',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        dividerColor: Colors.white.withValues(alpha: 0.08),
      ),
      home: const HomeShell(),
    );
  }
}
