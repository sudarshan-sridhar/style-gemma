import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

class EmailAuthForm extends ConsumerStatefulWidget {
  const EmailAuthForm({super.key});

  @override
  ConsumerState<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends ConsumerState<EmailAuthForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final authController = ref.read(authControllerProvider.notifier);

    if (_isLogin) {
      // Sign In
      await authController.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      // Register
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      // Validation
      if (name.isEmpty) {
        _showError('Please enter your name');
        return;
      }
      if (email.isEmpty) {
        _showError('Please enter your email');
        return;
      }
      if (password.length < 6) {
        _showError('Password must be at least 6 characters');
        return;
      }
      if (password != confirmPassword) {
        _showError('Passwords do not match');
        return;
      }

      // Register user
      await authController.registerWithEmail(email, password);

      // Set display name after registration
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.error != null) {
        _showError(next.error!);
      }
    });

    return Column(
      children: [
        // Name field (only for registration)
        if (!_isLogin) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Confirm password field (only for registration)
        if (!_isLogin) ...[
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 4),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: authState.loading ? null : _handleAuth,
            child: authState.loading
                ? const CircularProgressIndicator()
                : Text(_isLogin ? 'Sign In' : 'Create Account'),
          ),
        ),

        // Toggle between sign in / register
        TextButton(
          onPressed: authState.loading
              ? null
              : () {
                  setState(() => _isLogin = !_isLogin);
                  // Clear fields when switching
                  _nameController.clear();
                  _confirmPasswordController.clear();
                },
          child: Text(
            _isLogin ? 'Create a new account' : 'Already have an account?',
          ),
        ),
      ],
    );
  }
}
