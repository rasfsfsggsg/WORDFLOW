import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Check if user is already logged in
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3)); // 3 sec delay for animation

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final User? user = FirebaseAuth.instance.currentUser;

    if (isLoggedIn && user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Center the content
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo / Image with a slight bounce effect
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.elasticOut,
                height: 180, // Adjust height as needed
                child: Image.asset("assets/man.png"), // Use your image
              ),
              const SizedBox(height: 20),

              // App Name (Stylized)
              const Text(
                "WELCOME TO WORDFLOW",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36, // Bigger font
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.5, // Spacing for style
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.grey,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle (With subtle animation effect)
              const Text(
                "Your bridge to seamless communication!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
