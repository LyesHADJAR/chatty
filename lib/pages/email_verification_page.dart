import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/components/button.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  Timer? _timer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    
    // Check if the email is already verified
    _isEmailVerified = _auth.currentUser?.emailVerified ?? false;
    
    if (!_isEmailVerified) {
      _sendVerificationEmail();
      
      // Check email verification status periodically
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
  
  // Send verification email to user
  Future<void> _sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      await user?.sendEmailVerification();
      
      setState(() {
        _canResendEmail = false;
        _resendCooldown = 60; // 1 minute cooldown
      });
      
      _cooldownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (_resendCooldown > 0) {
            setState(() {
              _resendCooldown--;
            });
          } else {
            setState(() {
              _canResendEmail = true;
            });
            _cooldownTimer?.cancel();
          }
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent to ${user?.email}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Check if the email has been verified
  Future<void> _checkEmailVerified() async {
    await _auth.currentUser?.reload();
    
    setState(() {
      _isEmailVerified = _auth.currentUser?.emailVerified ?? false;
    });
    
    if (_isEmailVerified) {
      _timer?.cancel();
      // Navigate to home page after verification
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
  
  // Sign out from the app
  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_rounded,
              size: 100,
              color: theme.colorScheme.primary,
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Verify Your Email',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'We\'ve sent a verification email to:\n${_auth.currentUser?.email}',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Please check your inbox and click the verification link to activate your account.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            CustomButton(
              text: 'Refresh Status',
              onTap: _checkEmailVerified,
              prefixIcon: Icon(
                Icons.refresh,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: _canResendEmail 
                ? 'Resend Email' 
                : 'Resend in $_resendCooldown seconds',
              onTap: _canResendEmail ? _sendVerificationEmail : null,
              isOutlined: true,
              prefixIcon: Icon(
                Icons.send,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            TextButton(
              onPressed: _signOut,
              child: Text(
                'Back to Login',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}