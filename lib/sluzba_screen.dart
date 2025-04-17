// lib/screens/sluzba_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// <<< DODANO IMPORT dla url_launcher >>>
import 'package:url_launcher/url_launcher.dart';

class SluzbaScreen extends StatefulWidget {
  const SluzbaScreen({super.key});

  @override
  State<SluzbaScreen> createState() => _SluzbaScreenState();
}

class _SluzbaScreenState extends State<SluzbaScreen> {
  bool _isLoading = true;
  List<String> _userRoles = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRoles();
  }

  Future<void> _fetchUserRoles() async {
    // ... (Ta funkcja pozostaje bez zmian - wklejona dla kompletności) ...
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { if (mounted) { setState(() { _isLoading = false; _userRoles = []; }); } print("Błąd: Użytkownik niezalogowany na ekranie Służba."); return; }
    final userId = user.uid; print("Pobieranie ról dla użytkownika: $userId");
    try { final userDoc = await FirebaseFirestore.instance .collection('users') .doc(userId) .get(); if (userDoc.exists && mounted) { final data = userDoc.data(); final rolesFromDb = data?['roles']; if (rolesFromDb is List) { _userRoles = rolesFromDb.whereType<String>().toList(); print("Pobrane role: $_userRoles"); } else { print("Pole 'roles' nie znalezione lub nie jest listą dla użytkownika $userId."); _userRoles = []; } } else if (mounted) { print("Dokument użytkownika $userId nie istnieje."); _userRoles = []; } } catch (e) { print("Błąd podczas pobierania ról użytkownika: $e"); if (mounted) { _userRoles = []; } } finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }

  // Funkcja do budowania widoku, gdy użytkownik NIE MA ról (bez zmian)
  Widget _buildNoRolesView(BuildContext context) {
     // ... (Ta funkcja pozostaje bez zmian - wklejona dla kompletności) ...
    return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [ Icon( Icons.info_outline, size: 60, color: Colors.grey[400], ), const SizedBox(height: 20), const Text( "Nie jesteś jeszcze nigdzie zaangażowany?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center, ), const SizedBox(height: 10), Text( "Wypełnij formularz zgłoszeniowy, a my włączymy Cię do służby!", style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center, ), const SizedBox(height: 30), ElevatedButton.icon( icon: const Icon(Icons.description_outlined), label: const Text("Wypełnij formularz"), onPressed: _handleFormAction, style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), textStyle: const TextStyle(fontSize: 16), ), ), ], ), ), );
  }

  // --- ZMIANA TUTAJ: Funkcja budująca widok, gdy użytkownik MA role ---
  Widget _buildRolesView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _userRoles.length,
      itemBuilder: (context, index) {
        final role = _userRoles[index]; // Nazwa bieżącej roli

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek sekcji dla roli
              Text(
                "Materiały dla: $role",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
              const SizedBox(height: 12),

              // --- NOWY StreamBuilder do pobierania materiałów ---
              StreamBuilder<QuerySnapshot>(
                // Zapytanie do Firestore: pobierz materiały, gdzie 'rolaDocelowa' pasuje do bieżącej 'role'
                stream: FirebaseFirestore.instance
                    .collection('materialy')
                    .where('rolaDocelowa', isEqualTo: role) // Filtrowanie po roli!
                    .orderBy('uploadDate', descending: true) // Sortuj od najnowszych
                    .snapshots(), // snapshots() daje strumień aktualizacji na żywo
                builder: (context, snapshot) {
                  // Stan ładowania danych dla tej roli
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                  }
                  // Stan błędu
                  if (snapshot.hasError) {
                    print("Błąd pobierania materiałów dla roli '$role': ${snapshot.error}");
                    return const Text(
                      'Nie można załadować materiałów. Spróbuj ponownie później.',
                       style: TextStyle(color: Colors.red),
                    );
                  }
                  // Sprawdzenie, czy są dane i czy lista dokumentów nie jest pusta
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Brak dostępnych materiałów dla roli '$role'.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  // Mamy dane - wyświetlamy listę materiałów
                  final materialDocs = snapshot.data!.docs;

                  // Używamy Column, bo zazwyczaj nie będzie setek materiałów dla jednej roli
                  // Jeśli spodziewasz się bardzo wielu, można użyć zagnieżdżonego ListView
                  return Column(
                    children: materialDocs.map((doc) {
                      // Bezpieczne pobieranie danych z dokumentu materiału
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final title = data['title'] as String? ?? 'Brak tytułu';
                      final linkUrl = data['linkUrl'] as String?;
                      final description = data['description'] as String?; // Opcjonalny opis

                      // Zwracamy ListTile dla każdego materiału
                      return Card( // Używamy Card dla lepszego wyglądu
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Icon(Icons.link, color: Theme.of(context).primaryColor), // Ikona linku
                          title: Text(title),
                          subtitle: description != null ? Text(description) : null, // Pokaż opis, jeśli istnieje
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: linkUrl != null ? () => _launchURL(linkUrl) : null, // Akcja po kliknięciu
                          enabled: linkUrl != null, // Wyłącz klikanie, jeśli nie ma linku
                        ),
                      );
                    }).toList(), // map().toList() konwertuje mapowanie na listę widgetów
                  );
                },
              ),
              // --- Koniec StreamBuilder ---
            ],
          ),
        );
      },
    );
  }

  // --- DODANO: Funkcja do otwierania URL ---
  Future<void> _launchURL(String? urlString) async {
    if (urlString == null) return; // Nie rób nic, jeśli URL jest null

    final Uri url = Uri.parse(urlString); // Parsuj string do obiektu Uri
    try {
      // Spróbuj otworzyć URL
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
         // Jeśli launchUrl zwróci false, oznacza to, że nie można obsłużyć URL
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Błąd otwierania URL: $e');
      if (mounted) {
        // Pokaż błąd użytkownikowi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie można otworzyć linku: $urlString')),
        );
      }
    }
  }

  // Funkcja obsługująca naciśnięcie przycisku formularza (zmodyfikowana lekko dla URL)
  void _handleFormAction() async {
    print("Przycisk formularza naciśnięty!");
    // TODO: Wstaw TUTAJ prawdziwy link do Twojego formularza Google lub innego
    const String googleFormUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSd9YNdZei9U0HnEs9ApPm6_mDcTuWJjN7sycOj9cxz2fENlng/viewform?usp=dialog';
    await _launchURL(googleFormUrl); // Użyj funkcji _launchURL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Służba"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
             gradient: LinearGradient( colors: [Theme.of(context).primaryColorDark, Theme.of(context).primaryColorLight], begin: Alignment.topLeft, end: Alignment.bottomRight, ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userRoles.isEmpty
              ? _buildNoRolesView(context)
              : _buildRolesView(context),
    );
  }
}