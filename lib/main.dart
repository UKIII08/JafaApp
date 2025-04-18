import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // Upewnij się, że ten import jest
import 'package:cloud_firestore/cloud_firestore.dart'; // Potrzebny dla funkcji pomocniczej AuthWrapper

// <<< DODANY IMPORT dla formatowania daty >>>
import 'package:intl/date_symbol_data_local.dart';

// <<< DODANY IMPORT dla Firebase Messaging >>>
import 'package:firebase_messaging/firebase_messaging.dart';

// Zaimportuj swoje ekrany i konfigurację Firebase
import 'login_screen.dart';
import 'home_screen.dart';
// import 'firebase_options.dart'; // Odkomentuj jeśli używasz FlutterFire CLI

// --- Funkcja pomocnicza do tworzenia/aktualizacji usera (z poprzednich kroków) ---
// Jeśli nie masz jej w osobnym pliku, możesz ją umieścić tutaj
Future<void> _createOrUpdateUserDocument(User user) async {
  final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final timestamp = FieldValue.serverTimestamp(); // Użyj czasu serwera

  try {
    final docSnapshot = await userDocRef.get();
    Map<String, dynamic> dataToSet = {
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'lastLogin': timestamp,
    };
    if (!docSnapshot.exists) {
      dataToSet['createdAt'] = timestamp;
      dataToSet['roles'] = [];
      dataToSet['fcmTokens'] = [];
    }
    await userDocRef.set(dataToSet, SetOptions(merge: true));
    print("Dokument użytkownika stworzony/zaktualizowany dla ${user.uid}");
  } catch (e) {
    print("Błąd podczas tworzenia/aktualizacji dokumentu użytkownika: $e");
  }
}


// <<< HANDLER WIADOMOŚCI W TLE (NAJWYŻSZY POZIOM) >>>
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp(); // Rozważ, jeśli potrzebne dla logiki w tle
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification?.title} / ${message.notification?.body}');
  }
}


// --- Główna funkcja aplikacji ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
     // options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('pl_PL', null);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

// --- Główny Widget Aplikacji (MyApp) - ZE ZMIANAMI W THEME ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definiujemy Twój kolor jako kolor-ziarno
    const Color seedColor = Color.fromARGB(255, 109, 196, 223);

    return MaterialApp(
      title: 'Jafa App', // Możesz zmienić tytuł
      // --- ZMIENIONA DEFINICJA MOTYWU ---
      theme: ThemeData(
        // Używamy ColorScheme.fromSeed do wygenerowania palety
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          // Możesz tu dostosować jasność, np. brightness: Brightness.light,
        ),
        // Włączamy Material 3
        useMaterial3: true,

        // Stosujemy Twoją czcionkę Google Fonts do domyślnego motywu tekstowego
        textTheme: GoogleFonts.senTextTheme(ThemeData(brightness: Brightness.light).textTheme),

        // (Opcjonalnie) Globalne ustawienia dla AppBar, aby pasowały do nowego schematu
        // np. Domyślnie biały AppBar z ciemnym tekstem/ikonami
        appBarTheme: const AppBarTheme(
           backgroundColor: Colors.white, // Domyślne tło AppBar
           foregroundColor: Colors.black, // Domyślny kolor ikon i tytułu
           elevation: 1.0,              // Lekki cień
           // Możesz też ustawić styl tekstu tytułu, jeśli chcesz
           // titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
        ),
         // Możesz tu dodać inne globalne style dla komponentów...

      ),
      // --- KONIEC ZMIAN W THEME ---
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Widget AuthWrapper Z DODANYM WYWOŁANIEM _createOrUpdateUserDocument ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Wystąpił błąd podczas sprawdzania logowania.')));
        }
        if (snapshot.hasData) {
          // Użytkownik jest zalogowany
          final user = snapshot.data!;
          // <<< DODANO: Wywołanie funkcji tworzącej/aktualizującej dokument użytkownika >>>
          _createOrUpdateUserDocument(user);
          // Zwróć HomeScreen
          return const HomeScreen();
        } else {
          // Użytkownik jest wylogowany
          return const LoginScreen();
        }
      },
    );
  }
}