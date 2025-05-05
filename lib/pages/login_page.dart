import 'package:chatty/components/button.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/text_field.dart';
import 'package:chatty/components/social_button.dart';
import 'package:chatty/services/auth/auth_service.dart';

class LoginPage extends StatelessWidget {
  final void Function()? onTap;
  final Function toggleTheme;
  final bool isDarkMode;
  
  LoginPage({
    super.key, 
    this.onTap,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login(context) async {
    final authService = AuthService();

    try {
      await authService.signInWithEmailAndPassword(
        emailController.text, 
        passwordController.text
      );
    }
    catch(e) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_rounded,
                    size: 64,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App name
                Text(
                  'Welcome to Chatty',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Sign in to continue',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Email field
                CustomTextField(
                  hintText: 'Email', 
                  controller: emailController,
                  prefixIcon: Icons.email_outlined,
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                CustomTextField(
                  hintText: 'Password',
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                
                const SizedBox(height: 12),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login button
                CustomButton(
                  text: 'Login',
                  onTap: () => login(context),
                ),
                
                const SizedBox(height: 24),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.5)),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Social login button
                SocialButton(
                  icon: Icons.android, 
                  label: 'Google', 
                  onTap: () {}, 
                  context: context
                ),
                
                const SizedBox(height: 16),
                
                // Theme toggle
                TextButton.icon(
                  onPressed: () => toggleTheme(),
                  icon: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                  ),
                  label: Text(
                    isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}