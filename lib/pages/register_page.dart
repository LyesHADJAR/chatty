import 'package:chatty/components/button.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/text_field.dart';
import 'package:chatty/services/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  final Function toggleTheme;
  final bool isDarkMode;

  const RegisterPage({
    Key? key, 
    this.onTap,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isRegistering = false;
  String? _usernameError;

  // Check username availability with debounce
  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      setState(() => _usernameError = 'Username must be at least 3 characters');
      return;
    }
    
    // Check for valid characters (alphanumeric and underscore only)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameError = 'Only letters, numbers, and underscores allowed');
      return;
    }
    
    try {
      bool isAvailable = await _authService.isUsernameAvailable(username);
      setState(() => _usernameError = isAvailable ? null : 'Username already taken');
    } catch (e) {
      setState(() => _usernameError = 'Error checking username');
    }
  }

  void _register() async {
    // Validate fields
    if (_emailController.text.isEmpty || 
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    
    if (_usernameError != null) {
      _showError('Please fix the username error');
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    
    setState(() => _isRegistering = true);
    
    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );
      // Registration successful - AuthGate will handle navigation
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }
  
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // App logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 64,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 24),

                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Choose a unique username',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 32),

                // Email field
                CustomTextField(
                  hintText: 'Email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 12),
                
                // Username field
                CustomTextField(
                  hintText: 'Username',
                  controller: _usernameController,
                  prefixIcon: Icons.person_outline,
                  onChanged: (value) => _checkUsername(value),
                ),
                
                // Username error message
                if (_usernameError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _usernameError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Password field
                CustomTextField(
                  hintText: 'Password',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 12),

                // Confirm password field
                CustomTextField(
                  hintText: 'Confirm Password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 24),
                
                // Register button
                CustomButton(
                  text: 'Register',
                  onTap: _isRegistering ? null : _register,
                  isLoading: _isRegistering,
                ),

                const SizedBox(height: 20),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Theme toggle
                TextButton.icon(
                  onPressed: () => widget.toggleTheme(),
                  icon: Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                  ),
                  label: Text(
                    widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}