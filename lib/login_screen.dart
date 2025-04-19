import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Import dla Mesh Gradient
import 'package:mesh_gradient/mesh_gradient.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    // ... (Logika logowania - bez zmian) ...
    try { final googleUser = await GoogleSignIn().signIn(); if (googleUser == null) return; final googleAuth = await googleUser.authentication; final credential = GoogleAuthProvider.credential( accessToken: googleAuth.accessToken, idToken: googleAuth.idToken, ); await FirebaseAuth.instance.signInWithCredential(credential); } catch (e) { print('Błąd logowania Google: $e'); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Błąd logowania przez Google: ${e.toString()}')), ); } }
  }

  @override
  Widget build(BuildContext context) {
    // Definicja kolorów - użyjemy tylko głównego niebieskiego jako akcentu
    const Color blueAccentColor = Color.fromARGB(255, 109, 196, 223);
    // Możesz też zdefiniować bardzo jasny niebieski lub szary dla subtelności
    const Color offWhiteColor = Color(0xFFFAFAFA); // Lekko złamana biel

    return Scaffold(
      body: Stack(
        children: [
          // --- Warstwa 1: Animowany Gradient z delikatnym akcentem ---
          Positioned.fill(
            child: AnimatedMeshGradient(
              // --- ZMIANA TUTAJ: Lista kolorów z przewagą bieli ---
              colors: const [
                Colors.white,     // Lewy górny
                offWhiteColor,    // Prawy górny (lekko złamana biel)
                blueAccentColor,  // Lewy dolny (Twój niebieski akcent)
                Colors.white,     // Prawy dolny
              ],
              options: AnimatedMeshGradientOptions(
                // Możesz dostosować czas trwania, jeśli chcesz wolniejszą/szybszą animację
                // Eksperymentuj z tymi wartościami dla subtelniejszego efektu:
                //frequency: 0.7, // Mniejsza częstotliwość = większe, łagodniejsze plamy
                // amplitude: 0.3, // Mniejsza amplituda = mniej intensywne mieszanie
                // seed: 3,      // Zmień ziarno dla innego wzoru
              ),
            ),
          ),

          // --- Warstwa 2: Twoja dotychczasowa zawartość ---
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Center( child: Image.asset( 'assets/logo.png', height: 220, errorBuilder: (context, error, stackTrace) => const Icon(Icons.hide_image_outlined, size: 100, color: Colors.grey), ), ),
                const SizedBox(height: 40),
                Padding( padding: const EdgeInsets.symmetric(horizontal: 32), child: ElevatedButton.icon( style: ElevatedButton.styleFrom( backgroundColor: Colors.white, foregroundColor: Colors.black87, minimumSize: const Size(double.infinity, 50), elevation: 3, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300), ), ), icon: Image.asset( 'assets/google_logo.png', height: 24, errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24), ), label: const Text( 'Zaloguj się przez Google', style: TextStyle(fontSize: 16), ), onPressed: () => _signInWithGoogle(context), ), ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}