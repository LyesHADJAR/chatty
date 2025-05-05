import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/services/auth/login_or_register.dart';
import 'package:chatty/pages/home_page.dart';

class AuthGate extends StatelessWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const AuthGate({
    super.key, 
    required this.toggleTheme, 
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomePage(toggleTheme: toggleTheme, isDarkMode: isDarkMode);
          } else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
