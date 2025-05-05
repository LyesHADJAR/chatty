import 'package:chatty/components/button.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/text_field.dart';
import 'package:chatty/components/social_button.dart';
import 'package:chatty/services/auth/auth_service.dart';

class RegisterPage extends StatelessWidget {
  final void Function()? onTap;

  RegisterPage({super.key, this.onTap});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void register(BuildContext context) async {
    // get auth service
    final auth = AuthService();
    if (passwordController.text == confirmPasswordController.text) {
      try {
        await auth.signUpWithEmailAndPassword(
          emailController.text,
          passwordController.text,
        );
        // AuthGate will automatically handle the navigation
      } catch (e) {
        // show error message
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
          ),
        );
      }
    } else {
      // show error message
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Passwords do not match'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // App logo or icon could go here
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                CustomTextField(
                  hintText: 'Email',
                  controller: emailController,
                  prefixIcon: Icons.email_outlined,
                ),

                const SizedBox(height: 15),

                CustomTextField(
                  hintText: 'Password',
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                ),

                const SizedBox(height: 15),

                CustomTextField(
                  hintText: 'Confirm Password',
                  controller: confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                ),

                const SizedBox(height: 30),
                CustomButton(text: 'Register', onTap: () => register(context)),

                const SizedBox(height: 25),

                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Text(
                        'Or register with',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      icon: Icons.android,
                      label: 'Google',
                      onTap: () {},
                      context: context,
                    ),
                  ],
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