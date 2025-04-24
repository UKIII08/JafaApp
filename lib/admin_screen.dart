import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Import ekranu zarządzania użytkownikami
import 'admin_users_screen.dart'; // Upewnij się, że plik istnieje

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController(); // Używane jako 'description' dla events
  final _locationController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();
  final _notificationTitleController = TextEditingController();
  final _notificationBodyController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedCollection = 'aktualnosci';
  String? _editingDocumentId;

  // <<< NOWA ZMIENNA STANU DLA CHECKBOXA >>>
  bool _isSaturdayMeeting = false;

  List<String> _availableTopics = ['all'];
  String? _selectedNotificationTopic = 'all';
  bool _isLoadingTopics = true;

  String? _selectedTargetRole; // Dla roli docelowej ogłoszeń

  final functions = FirebaseFunctions.instanceFor(region: 'europe-west10'); // Dostosuj region

  @override
  void initState() {
    super.initState();
    _fetchUniqueRolesAndBuildTopics();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _googleMapsLinkController.dispose();
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    super.dispose();
  }

  // Funkcja _selectDate (bez zmian)
   Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
        if (_selectedCollection == 'events') {
             final TimeOfDay? pickedTime = await showTimePicker(
                 context: context,
                 initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
             );
             if (pickedTime != null) {
                 setState(() {
                     _selectedDate = DateTime(
                         picked.year,
                         picked.month,
                         picked.day,
                         pickedTime.hour,
                         pickedTime.minute,
                     );
                 });
             }
        } else {
             if (picked != _selectedDate) {
                  setState(() {
                      _selectedDate = picked;
                  });
             }
        }
    }
  }


  // Funkcja _submitForm (zmodyfikowana)
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final collection = FirebaseFirestore.instance.collection(_selectedCollection);
        Map<String, dynamic> data = {
          'title': _titleController.text.trim(),
          _selectedCollection == 'events' ? 'description' : 'content': _contentController.text.trim(),
          _selectedCollection == 'events' ? 'eventDate' : 'publishDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        };

        // Pola specyficzne dla kolekcji
        if (_selectedCollection == 'ogloszenia') {
          data['rolaDocelowa'] = _selectedTargetRole;
        } else if (_selectedCollection == 'events') {
          data['location'] = _locationController.text.trim();
          data['googleMapsLink'] = _googleMapsLinkController.text.trim();
          // <<< DODANO ZAPIS POLA 'sobota' >>>
          data['sobota'] = _isSaturdayMeeting;
          // Dodaj puste attendees tylko przy tworzeniu nowego wydarzenia
          if (_editingDocumentId == null) {
            data['attendees'] = {};
          }
        }

        if (_editingDocumentId == null) {
          data['createdAt'] = FieldValue.serverTimestamp();
          await collection.add(data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dodano!')),
            );
          }
        } else {
          data['updatedAt'] = FieldValue.serverTimestamp();
          await collection.doc(_editingDocumentId).update(data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Zaktualizowano!')),
            );
          }
        }
        _clearForm();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wystąpił błąd: $e')),
          );
        }
      }
    }
  }

  // Funkcja _deleteDocument (bez zmian)
  Future<void> _deleteDocument(String documentId) async {
      bool confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
            title: const Text('Potwierdzenie'),
            content: const Text('Czy na pewno chcesz usunąć ten element?'),
            actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Anuluj')),
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Usuń', style: TextStyle(color: Colors.red))),
            ],
          ),
      ) ?? false;

      if (!confirm || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection(_selectedCollection)
          .doc(documentId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usunięto!')),
        );
         if (documentId == _editingDocumentId) {
           _clearForm();
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wystąpił błąd: $e')),
        );
      }
    }
  }


  // Funkcja _editDocument (zmodyfikowana)
  void _editDocument(String documentId, Map<String, dynamic> data) {
    setState(() {
      _editingDocumentId = documentId;
      _titleController.text = data['title'] ?? '';
      _contentController.text = data[_selectedCollection == 'events' ? 'description' : 'content'] ?? '';

      final dateField = _selectedCollection == 'events' ? 'eventDate' : 'publishDate';
      if (data[dateField] is Timestamp) {
        _selectedDate = (data[dateField] as Timestamp).toDate();
      } else {
        _selectedDate = null;
      }

      // Ustaw pola specyficzne dla kolekcji
      if (_selectedCollection == 'ogloszenia') {
        String? roleFromDb = data['rolaDocelowa'];
        if (roleFromDb != null && _availableTopics.contains(roleFromDb) && roleFromDb != 'all') {
          _selectedTargetRole = roleFromDb;
        } else {
          _selectedTargetRole = null;
        }
        _locationController.clear();
        _googleMapsLinkController.clear();
        _isSaturdayMeeting = false; // Resetuj dla innych kolekcji
      } else if (_selectedCollection == 'events') {
        _locationController.text = data['location'] ?? '';
        _googleMapsLinkController.text = data['googleMapsLink'] ?? '';
        // <<< ODCZYT WARTOŚCI 'sobota' PRZY EDYCJI >>>
        // Ustaw domyślnie na false, jeśli pole nie istnieje
        _isSaturdayMeeting = data['sobota'] as bool? ?? false;
        _selectedTargetRole = null;
      } else {
        _selectedTargetRole = null;
        _locationController.clear();
        _googleMapsLinkController.clear();
        _isSaturdayMeeting = false; // Resetuj dla innych kolekcji
      }
    });
  }

  // Funkcja _clearForm (zmodyfikowana)
  void _clearForm() {
    setState(() {
      _editingDocumentId = null;
      _titleController.clear();
      _contentController.clear();
      _locationController.clear();
      _googleMapsLinkController.clear();
      _selectedDate = null;
      _selectedTargetRole = null;
      // <<< RESETOWANIE CHECKBOXA >>>
      _isSaturdayMeeting = false;
    });
  }

  // Funkcje _fetchUniqueRolesAndBuildTopics, _sendPushMessage (bez zmian)
   Future<void> _fetchUniqueRolesAndBuildTopics() async {
       if (!mounted) return;
    setState(() { _isLoadingTopics = true; });
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Set<String> uniqueRoles = {};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('roles') && data['roles'] is List) {
          final rolesList = List<dynamic>.from(data['roles']);
          for (var role in rolesList) {
            if (role is String && role.trim().isNotEmpty) {
              uniqueRoles.add(role.trim());
            }
          }
        }
      }
      final List<String> finalTopics = ['all', ...uniqueRoles.toList()..sort()];

      if (mounted) {
          setState(() {
            _availableTopics = finalTopics;
            if (!_availableTopics.contains(_selectedNotificationTopic)) {
                _selectedNotificationTopic = 'all';
            }
            if (_selectedTargetRole != null && !_availableTopics.contains(_selectedTargetRole)) {
                _selectedTargetRole = null;
            }
            _isLoadingTopics = false;
          });
      }
    } catch (e) {
       print("Błąd fetchUniqueRolesAndBuildTopics: $e");
      if (mounted) {
        setState(() {
          _availableTopics = ['all'];
          _selectedNotificationTopic = 'all';
          _selectedTargetRole = null;
          _isLoadingTopics = false;
        });
      }
    }
  }

   Future<void> _sendPushMessage() async {
    if (_notificationTitleController.text.trim().isEmpty ||
        _notificationBodyController.text.trim().isEmpty ||
        _selectedNotificationTopic == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wprowadź tytuł, treść i temat.')),
        );
      }
      return;
    }
    try {
      final callable = functions.httpsCallable('sendManualNotification');
      final result = await callable.call({
        'title': _notificationTitleController.text.trim(),
        'body': _notificationBodyController.text.trim(),
        'targetRole': _selectedNotificationTopic == 'all' ? null : _selectedNotificationTopic,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.data['message'] ?? 'Wysłano powiadomienie!')),
        );
        _notificationTitleController.clear();
        _notificationBodyController.clear();
        setState(() { _selectedNotificationTopic = 'all'; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Budowanie zapytania (bez zmian)
     Query query = FirebaseFirestore.instance.collection(_selectedCollection);
    if (_selectedCollection == 'aktualnosci') {
      query = query.orderBy('publishDate', descending: true);
    } else if (_selectedCollection == 'events') {
       query = query.orderBy('eventDate', descending: false);
    }
    else {
      query = query.orderBy('createdAt', descending: true);
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administratora'),
        actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Odśwież listę ról',
              onPressed: _fetchUniqueRolesAndBuildTopics,
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Wyloguj',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          if (_editingDocumentId != null)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Anuluj edycję',
              onPressed: _clearForm,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Zmieniono na ListView, aby pomieścić więcej pól
            children: [
              // Wybór kolekcji (bez zmian)
               DropdownButtonFormField<String>(
                 value: _selectedCollection,
                 items: ['aktualnosci', 'ogloszenia', 'events']
                     .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                     .toList(),
                 onChanged: (val) {
                   if (val != null) {
                     setState(() {
                       _selectedCollection = val;
                       _clearForm();
                     });
                   }
                 },
                 decoration: const InputDecoration(labelText: 'Wybierz Kolekcję'),
               ),
              // Tytuł (bez zmian)
               TextFormField(
                 controller: _titleController,
                 decoration: const InputDecoration(labelText: 'Tytuł'),
                 validator: (value) => value == null || value.trim().isEmpty ? 'Wprowadź tytuł' : null,
               ),
              // Treść / Opis (bez zmian)
               TextFormField(
                 controller: _contentController,
                 decoration: InputDecoration(labelText: _selectedCollection == 'events' ? 'Opis Wydarzenia' : 'Treść'),
                 maxLines: 4,
                 validator: (value) => value == null || value.trim().isEmpty ? 'Wprowadź treść/opis' : null,
               ),

              // Pola dla wydarzeń (zmodyfikowane)
              if (_selectedCollection == 'events') ...[
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Lokalizacja (np. adres)'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Wprowadź lokalizację' : null,
                ),
                TextFormField(
                  controller: _googleMapsLinkController,
                  decoration: const InputDecoration(labelText: 'Link Google Maps (opcjonalnie)'),
                   validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                              return 'Wprowadź poprawny link (http://... lub https://...)';
                          }
                      }
                      return null;
                   },
                ),
                // <<< DODANO CHECKBOX DLA SPOTKAŃ SOBOTNICH >>>
                CheckboxListTile(
                  title: const Text("Spotkanie sobotnie?"),
                  value: _isSaturdayMeeting,
                  onChanged: (bool? value) {
                    setState(() {
                      _isSaturdayMeeting = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading, // Checkbox po lewej
                  contentPadding: EdgeInsets.zero, // Usunięcie domyślnego paddingu
                ),
                // <<< KONIEC CHECKBOXA >>>
              ],

              // Wybór Daty (bez zmian)
               ListTile(
                 title: Text(_selectedDate == null
                     ? 'Wybierz datę${_selectedCollection == 'events' ? ' i godzinę' : ''}'
                     : 'Wybrana data: ${DateFormat(_selectedCollection == 'events' ? 'dd.MM.yyyy HH:mm' : 'dd.MM.yyyy', 'pl_PL').format(_selectedDate!)}'),
                 trailing: const Icon(Icons.calendar_today),
                 onTap: () => _selectDate(context),
               ),

              // Rola docelowa (bez zmian)
               if (_selectedCollection == 'ogloszenia')
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                   child: DropdownButtonFormField<String?>(
                     value: _selectedTargetRole,
                     hint: const Text('Wybierz rolę docelową...'),
                     items: [
                       const DropdownMenuItem<String?>(
                         value: null,
                         child: Text('Brak (dla wszystkich)'),
                       ),
                       ..._availableTopics
                           .where((topic) => topic != 'all')
                           .map((role) => DropdownMenuItem<String?>(
                                 value: role,
                                 child: Text(role),
                               )),
                     ],
                     onChanged: _isLoadingTopics ? null : (String? newValue) {
                       setState(() { _selectedTargetRole = newValue; });
                     },
                     decoration: InputDecoration(
                       labelText: 'Rola Docelowa (Opcjonalnie)',
                        suffixIcon: _isLoadingTopics
                            ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                            : null,
                     ),
                      disabledHint: const Text('Ładowanie ról...'),
                   ),
                 ),

              // Przycisk Zapisz/Aktualizuj (bez zmian)
               ElevatedButton(
                 onPressed: _submitForm,
                 child: Text(_editingDocumentId == null ? 'Zapisz' : 'Zaktualizuj'),
               ),
              const Divider(height: 32),

              // Lista elementów (bez zmian)
               StreamBuilder<QuerySnapshot>(
                 stream: query.snapshots(),
                 builder: (context, snapshot) {
                   if (snapshot.hasError) return Text('Błąd: ${snapshot.error}');
                   if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                     return const Center(child: Text('Brak danych w tej kolekcji.'));
                   }
                   return ListView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: snapshot.data!.docs.length,
                     itemBuilder: (context, index) {
                       final doc = snapshot.data!.docs[index];
                       final data = doc.data() as Map<String, dynamic>;
                       final dateField = _selectedCollection == 'events' ? 'eventDate' : (_selectedCollection == 'aktualnosci' ? 'publishDate' : 'createdAt');
                       final dateFormat = _selectedCollection == 'events' ? 'dd.MM.yyyy HH:mm' : (_selectedCollection == 'aktualnosci' ? 'dd.MM.yyyy' : 'dd.MM.yyyy HH:mm');
                       final datePrefix = _selectedCollection == 'events' ? 'Data: ' : (_selectedCollection == 'aktualnosci' ? 'Pub: ' : 'Dod: ');

                       return Card(
                         child: ListTile(
                           title: Text(data['title'] ?? 'Brak tytułu'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data[dateField] is Timestamp)
                                  Text('$datePrefix${DateFormat(dateFormat, 'pl_PL').format((data[dateField] as Timestamp).toDate())}', style: Theme.of(context).textTheme.bodySmall)
                                else
                                  Text('$datePrefix Brak daty', style: Theme.of(context).textTheme.bodySmall),
                                Text(data[_selectedCollection == 'events' ? 'description' : 'content'] ?? 'Brak treści/opisu', maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (_selectedCollection == 'events' && data['location'] != null && data['location'].isNotEmpty)
                                  Text('Lok: ${data['location']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                                // <<< WYŚWIETLANIE STANU 'sobota' NA LIŚCIE >>>
                                if (_selectedCollection == 'events' && data.containsKey('sobota'))
                                  Text('Sobotnie: ${data['sobota'] == true ? "Tak" : "Nie"}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: data['sobota'] == true ? Colors.green : Colors.grey)),
                                if (_selectedCollection == 'ogloszenia' && data['rolaDocelowa'] != null && data['rolaDocelowa'].isNotEmpty)
                                  Text('Rola: ${data['rolaDocelowa']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                              ],
                            ),
                           trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               IconButton(
                                 icon: const Icon(Icons.edit),
                                 onPressed: () => _editDocument(doc.id, data),
                               ),
                               IconButton(
                                 icon: const Icon(Icons.delete),
                                 onPressed: () => _deleteDocument(doc.id),
                               ),
                             ],
                           ),
                         ),
                       );
                     },
                   );
                 },
               ),

              const Divider(height: 32),
              // Sekcja powiadomień (bez zmian)
               TextFormField(
                 controller: _notificationTitleController,
                 decoration: const InputDecoration(labelText: 'Tytuł Powiadomienia'),
               ),
               TextFormField(
                 controller: _notificationBodyController,
                 decoration: const InputDecoration(labelText: 'Treść Powiadomienia'),
               ),
               DropdownButtonFormField<String>(
                 value: _selectedNotificationTopic,
                 items: _availableTopics.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                 onChanged: _isLoadingTopics ? null : (val) {
                  if (val != null) setState(() => _selectedNotificationTopic = val);
                 },
                 decoration: InputDecoration(
                   labelText: 'Temat/Rola',
                   suffixIcon: _isLoadingTopics ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                 ),
                  disabledHint: const Text('Ładowanie ról...'),
               ),
               ElevatedButton(
                 onPressed: _isLoadingTopics ? null : _sendPushMessage,
                 child: const Text('Wyślij Powiadomienie'),
               ),

              // Przycisk zarządzania użytkownikami (bez zmian)
              const Divider(height: 32),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('Zarządzaj Użytkownikami'),
                  style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}