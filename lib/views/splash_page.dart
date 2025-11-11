import 'package:flutter/material.dart';
import 'package:nawii/utils/app_colors.dart';
import 'package:nawii/views/login_page.dart';
import 'package:nawii/views/home_page.dart';
import 'package:nawii/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Iniciar animación
    _animationController.forward();

    // Navegar después de la animación y verificar autenticación
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Esperar a que la animación termine
    await Future.delayed(Duration(milliseconds: 2000));

    // Verificar si el usuario está autenticado
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    // Navegar a la pantalla correspondiente
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn ? HomePage() : LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildCustomImage(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomImage() {
    // Carga la imagen personalizada desde assets
    return Image.asset(
      'assets/images/image.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Si la imagen no existe, muestra un placeholder
        return Icon(
          Icons.image,
          size: 100,
          color: AppColors.primaryYellow,
        );
      },
    );
  }
}
