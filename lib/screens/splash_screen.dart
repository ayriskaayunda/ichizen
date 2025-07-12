import 'dart:async';

import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/constants/app_text_styles.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Wait for the splash screen animation to play
    await Future.delayed(const Duration(seconds: 3));

    // Initialize ApiService to load the token from SharedPreferences
    // This is crucial to ensure the token is available before checking login status
    await ApiService.init();

    // Check if a token exists in ApiService (which means a user is logged in)
    final isLoggedIn =
        ApiService.getToken() !=
        null; // Assuming ApiService has a getter for token

    final nextRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;

    if (!mounted) return;

    // Navigate to the appropriate route
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Mengubah warna background menjadi putih
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          // Mengganti Column dengan Image.asset
          child: Image.asset(
            'assets/images/logo.png', // Pastikan Anda memiliki gambar logo di path ini
            width: size.width * 0.8, // Menyesuaikan ukuran gambar
          ),
        ),
      ),
    );
  }
}
