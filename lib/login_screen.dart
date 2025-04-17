import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd logowania: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // 🔶 Logo
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 220,
              ),
            ),

            const SizedBox(height: 40),

            // 🔘 Google Sign-In Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 24,
                ),
                label: const Text(
                  'Zaloguj się przez Google',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () => _signInWithGoogle(context),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
