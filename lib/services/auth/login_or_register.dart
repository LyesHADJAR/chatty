import 'package:flutter/material.dart';
import 'package:chatty/pages/login_page.dart';
import 'package:chatty/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const LoginOrRegister({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = true;

  void toggleView() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: toggleView, 
        toggleTheme: widget.toggleTheme, 
        isDarkMode: widget.isDarkMode
      );
    } else {
      return RegisterPage(
        onTap: toggleView,
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode
      );
    }
  }
}