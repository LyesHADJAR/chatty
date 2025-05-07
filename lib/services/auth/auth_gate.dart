import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/services/auth/login_or_register.dart';
import 'package:chatty/pages/home_page.dart';
import 'package:chatty/pages/email_verification_page.dart';

class AuthGate extends StatelessWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const AuthGate({
    Key? key, 
    required this.toggleTheme, 
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // If user is logged in
          if (snapshot.hasData) {
            final user = snapshot.data!;
            
            // Check if email is verified
            if (!user.emailVerified) {
              return const EmailVerificationPage();
            }
            
            // User is verified, go to home page
            return HomePage(toggleTheme: toggleTheme, isDarkMode: isDarkMode);
          } 
          
          // If user is not logged in
          return LoginOrRegister(
            toggleTheme: toggleTheme,
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }
}