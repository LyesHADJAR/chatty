import 'package:flutter/material.dart';
import 'package:chatty/components/button.dart';
import 'package:chatty/components/text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    // Validate inputs
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create credential with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Try again later';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update your password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Enter your current password and a new password',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 32),
            
            CustomTextField(
              hintText: 'Current Password',
              controller: _currentPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              hintText: 'New Password',
              controller: _newPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            
            const SizedBox(height: 16),
            
            CustomTextField(
              hintText: 'Confirm New Password',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            
            const SizedBox(height: 32),
            
            CustomButton(
              text: 'Update Password',
              onTap: _isLoading ? null : _changePassword,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}