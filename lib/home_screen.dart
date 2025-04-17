import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <<< Dodaj import dla formatowania daty

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Używamy email jako fallback jeśli displayName jest nullem
    final userName = user?.displayName ?? user?.email ?? "Użytkowniku";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Główny'),
        // Hamburger menu jest dodawane automatycznie, gdy jest Drawer,
        // ale jeśli chcesz własną ikonę/logikę, Twój kod jest OK.
        // Poniżej alternatywa, jeśli AppBar sam ma dodać ikonę:
        // automaticallyImplyLeading: true,
        actions: [
          // Możesz tu dodać inne akcje, np. ikonę profilu
        ],
      ),
      drawer: Drawer(
        child: ListView(
          // Ważne: Usunięcie paddingu z ListView, jeśli DrawerHeader go pokrywa
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              // Możesz tu wyświetlić np. dane użytkownika
              child: Text(
                "Menu Główne\nWitaj, $userName", // Wyświetlamy nazwę użytkownika
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text("Ustawienia"),
              // onTap: () { /* Logika dla Ustawień */ Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Wyloguj"),
              onTap: () async { // <<< Dodana akcja wylogowania
                Navigator.pop(context); // Zamknij szufladę
                await FirebaseAuth.instance.signOut();
                // AuthWrapper automatycznie przełączy na LoginScreen
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
            Text("Witaj, $userName 👋", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), // Użycie stylu z motywu
            const SizedBox(height: 20),
            Text("Aktualności", style: Theme.of(context).textTheme.titleLarge), // Użycie stylu z motywu
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // ### ZMIANA TUTAJ: Sortowanie po 'publishDate' ###
                stream: FirebaseFirestore.instance
                    .collection('aktualnosci')
                    .orderBy('publishDate', descending: true) // Sortuj po dacie publikacji
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print("Błąd Firestore: ${snapshot.error}"); // Wypisz błąd do konsoli debugowania
                    return const Center(child: Text('Nie można załadować aktualności. Spróbuj ponownie później.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Sprawdzenie czy snapshot.data nie jest nullem i czy docs nie jest nullem
                  final docs = snapshot.data?.docs;
                  if (docs == null || docs.isEmpty) {
                    return const Center(child: Text("Brak aktualności."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      // Bezpieczniejsze pobieranie danych
                      final data = docs[index].data() as Map<String, dynamic>?; // Użyj ? dla bezpieczeństwa

                      // Jeśli data jest nullem, zwróć pusty kontener
                      if (data == null) {
                         return const SizedBox.shrink(); // Lub inny placeholder
                      }

                      // ### ZMIANA TUTAJ: Użycie 'title' i 'content' ###
                      final title = data['title'] as String? ?? "Bez tytułu";
                      final content = data['content'] as String? ?? "Brak treści";

                      // Formatowanie daty
                      final timestamp = data['publishDate'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat('dd.MM.yyyy HH:mm', 'pl_PL').format(timestamp.toDate()) // Format polski
                          : 'Brak daty';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Zaokrąglone rogi
                        child: ListTile(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$content\nOpublikowano: $formattedDate'), // Dodanie sformatowanej daty
                          isThreeLine: true, // Pozwala na więcej miejsca dla subtitle
                          // Możesz dodać onTap, aby przejść do szczegółów aktualności
                          // onTap: () { /* Nawigacja do szczegółów */ },
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