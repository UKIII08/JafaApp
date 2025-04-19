// lib/screens/wydarzenie_detail_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Potrzebne do _fetchUserName
import 'package:intl/intl.dart';

class WydarzenieDetailScreen extends StatefulWidget {
  final String eventId;
  // Możesz dodać opcjonalne parametry dla szybszego ładowania początkowego
  // final String? initialTitle;
  // final Timestamp? initialDate;

  const WydarzenieDetailScreen({
    super.key,
    required this.eventId,
    // this.initialTitle,
    // this.initialDate,
  });

  @override
  State<WydarzenieDetailScreen> createState() => _WydarzenieDetailScreenState();
}

class _WydarzenieDetailScreenState extends State<WydarzenieDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Funkcja pomocnicza do formatowania daty (można ją też wydzielić do osobnego pliku utils)
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Brak daty';
    return DateFormat('dd.MM.yyyy HH:mm', 'pl_PL').format(timestamp.toDate());
  }

  // Funkcja pomocnicza do pobierania nazwy użytkownika (potrzebna tutaj)
  Future<String> _fetchUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['displayName'] as String? ?? data?['name'] as String? ?? 'Brak imienia';
      } else {
        return 'Użytkownik nieznaleziony';
      }
    } catch (e) {
      print('Błąd pobierania nazwy użytkownika $userId: $e');
      return 'Błąd';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Możemy ustawić tytuł dynamicznie po załadowaniu danych
        // title: Text(widget.initialTitle ?? 'Szczegóły wydarzenia'),
        title: const Text('Szczegóły wydarzenia'),
      ),
      // Używamy StreamBuilder, aby nasłuchiwać zmian w DANYM wydarzeniu (np. gdy ktoś się dopisze)
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          // Stany ładowania i błędów dla samego dokumentu wydarzenia
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Błąd ładowania danych wydarzenia.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Nie znaleziono wydarzenia.'));
          }

          // Mamy dane wydarzenia
          final eventData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Pobieramy dane do wyświetlenia
          final title = eventData['title'] as String? ?? 'Bez tytułu';
          final description = eventData['description'] as String? ?? '';
          final eventDate = eventData['eventDate'] as Timestamp?;
          final location = eventData['location'] as String?;

          // Pobieramy mapę obecności (userId -> Timestamp)
          final attendeesData = eventData['attendees'];
          final Map<String, dynamic> attendees = (attendeesData is Map)
              ? attendeesData.cast<String, dynamic>()
              : {};

          return ListView( // Używamy ListView, aby zawartość mogła się przewijać
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Szczegóły Wydarzenia ---
              Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row( children: [ Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text( _formatDate(eventDate), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500), ), ], ),
              const SizedBox(height: 8),
               if (location != null && location.isNotEmpty) Padding( padding: const EdgeInsets.only(top: 4.0), child: Row( children: [ Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]), const SizedBox(width: 8), Expanded(child: Text(location, style: TextStyle(fontSize: 16, color: Colors.grey[800]))), ], ), ),
              const SizedBox(height: 16),
              if (description.isNotEmpty) Text(description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 16)),
              // --- Koniec Szczegółów Wydarzenia ---

              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),

              // --- Sekcja Listy Uczestników ---
              Text(
                'Lista uczestników (${attendees.length}):',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Wyświetl listę lub informację o braku zapisanych
              if (attendees.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Nikt jeszcze się nie zapisał.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                )
              else
                // Budujemy listę imion używając FutureBuilder
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: attendees.keys.map((attendeeId) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0), // Odstęp między nazwiskami
                      child: FutureBuilder<String>(
                        future: _fetchUserName(attendeeId),
                        builder: (context, nameSnapshot) {
                          if (nameSnapshot.connectionState == ConnectionState.waiting) {
                            return Row(children: [ SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 1.5)), SizedBox(width: 8), Text('Ładowanie...', style: TextStyle(color: Colors.grey))]);
                          }
                          // Fallback w razie błędu/braku danych
                           String fallbackText = 'Brak danych (ID: ${attendeeId.substring(0, math.min(6, attendeeId.length))}...)';
                           bool displayFallback = true;
                           if (nameSnapshot.hasError) {
                              fallbackText = 'Błąd (ID: ${attendeeId.substring(0, math.min(6, attendeeId.length))}...)';
                           } else if (!nameSnapshot.hasData || nameSnapshot.data!.isEmpty || ['Użytkownik nieznaleziony', 'Brak imienia', 'Błąd'].contains(nameSnapshot.data)) {
                               fallbackText = '${nameSnapshot.data ?? 'Brak danych'} (ID: ${attendeeId.substring(0, math.min(6, attendeeId.length))}...)';
                           } else {
                              displayFallback = false;
                           }

                          return Row( // Dodajemy ikonkę przy nazwisku
                            children: [
                              Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                displayFallback ? fallbackText : nameSnapshot.data!,
                                style: displayFallback
                                       ? const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 15)
                                       : const TextStyle(fontSize: 16),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              // --- Koniec Sekcji Listy Uczestników ---
            ],
          );
        },
      ),
    );
  }
}