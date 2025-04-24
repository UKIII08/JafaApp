import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'dart:async'; // Potrzebne do Timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// Dodajemy SingleTickerProviderStateMixin do obsługi AnimationController
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false; // Stan do śledzenia procesu logowania

  // Kontroler i zmienne do animacji wejścia
  late AnimationController _animationController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Inicjalizacja kontrolera animacji
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Czas trwania całej animacji
    );

    // Definicja animacji dla logo (przesunięcie i zanikanie)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        // Logo pojawia się w pierwszej połowie animacji
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Definicja animacji dla przycisku (przesunięcie i zanikanie)
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        // Przycisk pojawia się z opóźnieniem, w drugiej połowie animacji
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
     _buttonSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Uruchomienie animacji po krótkim opóźnieniu dla lepszego efektu
    Timer(const Duration(milliseconds: 300), () {
       if (mounted) { // Sprawdź czy widget jest nadal w drzewie
         _animationController.forward();
       }
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // Pamiętaj o zwolnieniu kontrolera
    super.dispose();
  }


  Future<void> _signInWithGoogle(BuildContext context) async {
    // Pokaż wskaźnik ładowania
    setState(() {
      _isLoading = true;
    });

    try {
      // Wyloguj, aby upewnić się, że użytkownik może wybrać konto za każdym razem
      // Rozważ, czy na pewno tego chcesz. Czasem lepiej pozwolić na automatyczne logowanie.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      // Jeśli użytkownik anulował wybór konta
      if (googleUser == null) {
         setState(() { _isLoading = false; }); // Ukryj ładowanie
         return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Logowanie do Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Nie musimy już ukrywać ładowania tutaj, bo nastąpi nawigacja do innego ekranu
      // Jeśli nie ma nawigacji, dodaj: if (mounted) setState(() { _isLoading = false; });

    } catch (e) {
      print('Błąd logowania Google: $e');
       if (mounted) { // Sprawdź czy widget jest nadal w drzewie
         setState(() { _isLoading = false; }); // Ukryj ładowanie w razie błędu
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Błąd logowania przez Google: ${e.toString()}')),
         );
       }
    }
    // Nie resetuj _isLoading tutaj jeśli nawigacja następuje automatycznie po udanym logowaniu
    // przez listener FirebaseAuth.instance.authStateChanges()
  }


  @override
  Widget build(BuildContext context) {
    const Color blueAccentColor = Color.fromARGB(255, 133, 221, 235);
    const Color offWhiteColor = Color(0xFFFAFAFA);

    return Scaffold(
      body: Stack(
        children: [
          // Tło z gradientem - bez zmian
          Positioned.fill(
            child: AnimatedMeshGradient(
              colors: const [
                Colors.white,
                offWhiteColor,
                Color.fromARGB(255, 25, 222, 248),
                Colors.white,
              ],
              options: AnimatedMeshGradientOptions(),
            ),
          ),
          SafeArea(
            child: Padding( // Dodajemy Padding dla estetyki
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animowane Logo
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: SlideTransition(
                      position: _logoSlideAnimation,
                      child: Center(
                        child: Image.asset(
                          'assets/logo.png', // Upewnij się, że ścieżka jest poprawna
                          height: 200, // Trochę mniejsze dla balansu
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.hide_image_outlined,
                                      size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60), // Większy odstęp

                  // Animowany Przycisk Logowania lub Wskaźnik Ładowania
                  FadeTransition(
                    opacity: _buttonFadeAnimation,
                    child: SlideTransition(
                      position: _buttonSlideAnimation,
                      // Jeśli trwa logowanie, pokaż wskaźnik, w przeciwnym razie przycisk
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // Kolor tła
                                foregroundColor: Colors.black87, // Kolor tekstu i ikony
                                minimumSize: const Size(double.infinity, 55), // Zwiększona wysokość
                                elevation: 4, // Większy cień
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16), // Bardziej zaokrąglone rogi
                                  // Usunięto border boczny dla czystszego wyglądu, można przywrócić
                                  // side: BorderSide(color: Colors.grey.shade300),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15) // Wewnętrzny padding
                              ),
                              icon: Image.asset(
                                'assets/google_logo.png', // Upewnij się, że ścieżka jest poprawna
                                height: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(width: 24), // Placeholder w razie błędu
                              ),
                              label: const Text(
                                'Zaloguj się przez Google',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500), // Pogrubiony tekst
                              ),
                              onPressed: () => _signInWithGoogle(context),
                            ),
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
