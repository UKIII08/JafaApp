import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // Upewnij się, że ten import jest

// <<< DODAJ TEN IMPORT dla inicjalizacji formatowania daty >>>
import 'package:intl/date_symbol_data_local.dart';

// Zaimportuj swoje ekrany i konfigurację Firebase
import 'login_screen.dart';
import 'home_screen.dart';
// import 'firebase_options.dart'; // Odkomentuj jeśli używasz FlutterFire CLI

// --- AuthWrapper musi być gdzieś zdefiniowany ---
// Możesz go zostawić na dole tego pliku lub przenieść do osobnego pliku i zaimportować
// import 'auth_wrapper.dart';

void main() async {
  // Ta linia już była:
  WidgetsFlutterBinding.ensureInitialized();

  // Ta linia już była:
  await Firebase.initializeApp(
     // options: DefaultFirebaseOptions.currentPlatform, // Odkomentuj jeśli używasz
  );

  // <<< DODANA LINIA - Inicjalizacja dla formatowania daty 'pl_PL' >>>
  await initializeDateFormatting('pl_PL', null);

  // Ta linia już była:
  runApp(const MyApp());
}

// Klasa MyApp (bez zmian - już zawierała motyw z czcionką Sen)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definiujemy bazowy motyw (możesz tu dodać więcej ustawień)
    final ThemeData baseTheme = ThemeData(
      primarySwatch: Colors.blue, // Przykładowy kolor główny
      // np. scaffoldBackgroundColor: Colors.grey[100],
    );

    return MaterialApp(
      title: 'Logowanie', // Możesz zmienić tytuł aplikacji
      theme: baseTheme.copyWith(
        // Ustawienie czcionki Sen za pomocą google_fonts (już było)
        textTheme: GoogleFonts.senTextTheme(baseTheme.textTheme),
      ),
      home: const AuthWrapper(), // Kieruje do widgetu sprawdzającego stan logowania
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget AuthWrapper (bez zmian)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Wystąpił błąd podczas sprawdzania logowania.'),
            ),
          );
        }
        if (snapshot.hasData) {
          // Zalogowany -> HomeScreen
          return const HomeScreen();
        } else {
          // Wylogowany -> LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}


// --- PRZYKŁADOWE EKRANY ---
// Poniżej znajdują się przykładowe definicje, Twoje powinny być
// w osobnych plikach (login_screen.dart, home_screen.dart)

/*
// Przykładowy plik: login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importuj swoje metody logowania, np. Google Sign-In

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle() async {
    try {
      print('Logika logowania przez Google (do implementacji)...');
      // Tutaj logika logowania z użyciem FirebaseAuth.instance.signInWithCredential
    } on FirebaseAuthException catch (e) {
      print('Błąd logowania Firebase: ${e.code} - ${e.message}');
    } catch (e) {
      print('Inny błąd logowania: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logowanie')),
      body: Center(
        child: ElevatedButton(
          onPressed: _signInWithGoogle,
          child: const Text('Zaloguj się przez Google'),
        ),
      ),
    );
  }
}
*/

/*
// Przykładowy plik: home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Potrzebne dla Timestamp
import 'package:intl/intl.dart'; // Potrzebne dla DateFormat

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

 @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? "Użytkowniku";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Główny'),
      ),
      drawer: Drawer( // Dodany przykładowy Drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text("Menu - $userName", style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Ustawienia"),
              onTap: () { Navigator.pop(context); /* Logika Ustawień */ },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Wyloguj"),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Witaj, $userName 👋", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Aktualności", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('aktualnosci')
                    .orderBy('publishDate', descending: true) // Używamy 'publishDate'
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print("Błąd Firestore: ${snapshot.error}");
                    return const Center(child: Text('Nie można załadować aktualności.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs;
                  if (docs == null || docs.isEmpty) {
                    return const Center(child: Text("Brak aktualności."));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox.shrink();

                      final title = data['title'] as String? ?? "Bez tytułu";
                      final content = data['content'] as String? ?? "Brak treści";
                      final timestamp = data['publishDate'] as Timestamp?; // Używamy 'publishDate'
                      final formattedDate = timestamp != null
                          ? DateFormat('dd.MM.yyyy HH:mm', 'pl_PL').format(timestamp.toDate())
                          : 'Brak daty';

                      return Card(
                         elevation: 3,
                         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$content\nOpublikowano: $formattedDate'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/