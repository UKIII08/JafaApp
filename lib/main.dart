import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // Upewnij się, że ten import jest

// <<< DODANY IMPORT dla formatowania daty >>>
import 'package:intl/date_symbol_data_local.dart';

// <<< DODANY IMPORT dla Firebase Messaging >>>
import 'package:firebase_messaging/firebase_messaging.dart';

// Zaimportuj swoje ekrany i konfigurację Firebase
import 'login_screen.dart';
import 'home_screen.dart';
// import 'firebase_options.dart'; // Odkomentuj jeśli używasz FlutterFire CLI

// --- AuthWrapper musi być gdzieś zdefiniowany (np. na dole pliku) ---

// <<< HANDLER WIADOMOŚCI W TLE (NAJWYŻSZY POZIOM) >>>
// Musi być poza klasą! Adnotacja @pragma jest ważna.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ważne: Nie inicjalizuj tutaj FirebaseApp ponownie, jeśli zostało już zainicjowane w main(),
  // chyba że napotkasz problemy specyficzne dla startu w tle.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification?.title} / ${message.notification?.body}');
  }
  // Tu można dodać logikę specyficzną dla tła, np. lokalny zapis.
  // Nie należy tu aktualizować UI.
}


// --- Główna funkcja aplikacji ---
void main() async {
  // Inicjalizacja Flutter Binding
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja Firebase
  await Firebase.initializeApp(
     // options: DefaultFirebaseOptions.currentPlatform, // Odkomentuj jeśli używasz FlutterFire CLI
  );

  // Inicjalizacja formatowania daty dla języka polskiego
  await initializeDateFormatting('pl_PL', null);

  // <<< ZAREJESTRUJ HANDLER WIADOMOŚCI W TLE >>>
  // Należy to zrobić po inicjalizacji Firebase, a przed runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Uruchomienie aplikacji
  runApp(const MyApp());
}

// --- Główny Widget Aplikacji (MyApp) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definiujemy bazowy motyw
    final ThemeData baseTheme = ThemeData(
      primarySwatch: Colors.blue, // Przykładowy kolor główny
    );

    return MaterialApp(
      title: 'Logowanie', // Tytuł aplikacji
      theme: baseTheme.copyWith(
        // Ustawienie czcionki Sen
        textTheme: GoogleFonts.senTextTheme(baseTheme.textTheme),
      ),
      // Używamy AuthWrapper do zarządzania stanem logowania
      home: const AuthWrapper(),
      // Wyłączenie banera Debug
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Widget AuthWrapper ---
// Sprawdza stan autentykacji i kieruje do odpowiedniego ekranu
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Stan ładowania
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        // Stan błędu
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Wystąpił błąd podczas sprawdzania logowania.'),
            ),
          );
        }
        // Sprawdzenie danych użytkownika
        if (snapshot.hasData) {
          // Zalogowany -> Przejdź do HomeScreen
          return const HomeScreen();
        } else {
          // Wylogowany -> Przejdź do LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}