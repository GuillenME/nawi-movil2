import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/home_page.dart';
import 'package:nawii/services/auth_service.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/widgets/nawi_logo.dart';

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
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NawiLogo(size: 80, showText: true, showTagline: false),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return HomePage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
