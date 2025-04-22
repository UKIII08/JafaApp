import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle(BuildContext context) async {
  try {
    await _googleSignIn.signOut(); // NIE disconnect

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    print('Błąd logowania Google: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd logowania przez Google: ${e.toString()}')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    const Color blueAccentColor = Color.fromARGB(255, 109, 196, 223);
    const Color offWhiteColor = Color(0xFFFAFAFA);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedMeshGradient(
              colors: const [
                Colors.white,
                offWhiteColor,
                blueAccentColor,
                Colors.white,
              ],
              options: AnimatedMeshGradientOptions(),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 220,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.hide_image_outlined,
                                size: 100, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 40),
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
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 24),
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
        ],
      ),
    );
  }
}