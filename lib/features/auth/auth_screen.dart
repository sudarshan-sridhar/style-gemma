import 'package:flutter/material.dart';

import 'email_auth_form.dart';
import 'google_sign_in_button.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✨ DRESS LOGO - 300PX + CENTERED
              Center(
                child: Image.asset(
                  'assets/images/logo_dress.png',
                  height: 300, // ✅ 300PX
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              const EmailAuthForm(),
              const SizedBox(height: 24),
              const GoogleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }
}
