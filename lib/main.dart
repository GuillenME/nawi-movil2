import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/home_page.dart';
import 'package:nawii/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manejar errores no capturados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Error no capturado: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Manejar errores de zonas asíncronas
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Error en zona asíncrona: $error');
    print('Stack trace: $stack');
    return true;
  };

  // Inicializar MobileAds de forma segura
  try {
    await MobileAds.instance.initialize();
    print('MobileAds inicializado correctamente');
  } catch (e) {
    print('Error inicializando MobileAds: $e');
    // Si MobileAds falla, continuamos sin él por ahora
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error inicializando Firebase: $e');
    // Si Firebase falla, continuamos sin él por ahora
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nawi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_taxi,
                    size: 80,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // Manejar errores
        if (snapshot.hasError) {
          print('Error en AuthWrapper: ${snapshot.error}');
          // Si hay error, mostrar login por defecto
          return const LoginPage();
        }

        if (snapshot.data == true) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
