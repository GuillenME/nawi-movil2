import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nawii/views/splash_page.dart';
import 'package:nawii/utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error inicializando Firebase: $e');
    // Si Firebase falla, continuamos sin él por ahora
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NAWI',
      theme: ThemeData(
        primaryColor: AppColors.primaryDark,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryDark,
          secondary: AppColors.primaryYellow,
          surface: AppColors.surfaceColor,
          background: AppColors.backgroundColor,
          error: AppColors.errorColor,
          onPrimary: AppColors.textOnPrimary,
          onSecondary: AppColors.textOnAccent,
          onSurface: AppColors.textPrimary,
          onBackground: AppColors.textPrimary,
          onError: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.mediumGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.mediumGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
