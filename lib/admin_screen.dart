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
  final _contentController = TextEditingController();
  final _notificationTitleController = TextEditingController();
  final _notificationBodyController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedCollection = 'aktualnosci'; // Domyślnie aktualności
  String? _editingDocumentId;

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
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final collection = FirebaseFirestore.instance.collection(_selectedCollection);
        Map<String, dynamic> data = {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          // Zapisuj publishDate jako Timestamp lub null
          'publishDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        };
        if (_selectedCollection == 'ogloszenia' && _selectedTargetRole != null) {
          data['rolaDocelowa'] = _selectedTargetRole;
        } else if (_selectedCollection == 'ogloszenia') {
            // Upewnij się, że pole jest null jeśli nie wybrano roli
            data['rolaDocelowa'] = null;
        }


        if (_editingDocumentId == null) {
          // Zapisuj createdAt tylko przy dodawaniu, jeśli chcesz sortować po nim inne kolekcje
           if (_selectedCollection != 'aktualnosci') { // Nie dodawaj createdAt dla aktualnosci
                data['createdAt'] = FieldValue.serverTimestamp();
           }
          await collection.add(data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dodano!')),
            );
          }
        } else {
           // Opcjonalnie dodaj updatedAt
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

  void _editDocument(String documentId, Map<String, dynamic> data) {
    setState(() {
      _editingDocumentId = documentId;
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      if (data['publishDate'] is Timestamp) {
        _selectedDate = (data['publishDate'] as Timestamp).toDate();
      } else {
        _selectedDate = null;
      }

      if (_selectedCollection == 'ogloszenia') {
         String? roleFromDb = data['rolaDocelowa'];
         if (roleFromDb != null && _availableTopics.contains(roleFromDb) && roleFromDb != 'all') {
            _selectedTargetRole = roleFromDb;
         } else {
            _selectedTargetRole = null;
         }
      } else {
        _selectedTargetRole = null;
      }
    });
  }

  void _clearForm() {
    setState(() {
      _editingDocumentId = null;
      // Nie resetujemy klucza formularza, aby uniknąć problemów z dropdownem
      // _formKey.currentState?.reset();
      _titleController.clear();
      _contentController.clear();
      _selectedDate = null;
      _selectedTargetRole = null;
    });
  }


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
    // Budowanie zapytania do StreamBuilder w zależności od wybranej kolekcji
    Query query = FirebaseFirestore.instance.collection(_selectedCollection);

    // Zastosuj odpowiednie sortowanie
    if (_selectedCollection == 'aktualnosci') {
      // Sortuj aktualności po dacie publikacji (zakładając, że istnieje i jest Timestamp)
      query = query.orderBy('publishDate', descending: true);
    } else {
      // Dla innych kolekcji (ogloszenia, events) sortuj po dacie utworzenia
      // Zakładamy, że te kolekcje MAJĄ pole createdAt typu Timestamp
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
          child: ListView(
            children: [
              // Pierwszy Dropdown - bez zmian
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tytuł'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Wprowadź tytuł' : null,
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Treść'),
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty ? 'Wprowadź treść' : null,
              ),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Wybierz datę'
                    : 'Wybrana data: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),

              // Drugi Dropdown (Rola Docelowa) - bez zmian
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

              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_editingDocumentId == null ? 'Zapisz' : 'Zaktualizuj'),
              ),
              const Divider(height: 32),

              // *** MODYFIKACJA: Użycie dynamicznego zapytania 'query' ***
              StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(), // Użycie zbudowanego zapytania
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
                      return Card(
                        child: ListTile(
                          title: Text(data['title'] ?? 'Brak tytułu'),
                           subtitle: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Wyświetlanie daty (bez zmian)
                               if (data['publishDate'] is Timestamp)
                                 Text('Pub: ${DateFormat('dd.MM.yyyy').format((data['publishDate'] as Timestamp).toDate())}', style: Theme.of(context).textTheme.bodySmall)
                               else if (data['createdAt'] is Timestamp) // Dla innych kolekcji
                                 Text('Dod: ${DateFormat('dd.MM.yyyy HH:mm').format((data['createdAt'] as Timestamp).toDate())}', style: Theme.of(context).textTheme.bodySmall),
                               Text(data['content'] ?? 'Brak treści'),
                               if (_selectedCollection == 'ogloszenia' && data['rolaDocelowa'] != null && data['rolaDocelowa'].isNotEmpty)
                                 Text('Rola: ${data['rolaDocelowa']}'),
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
              // *** KONIEC MODYFIKACJI ***

              const Divider(height: 32),
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

              // Przycisk nawigacji - bez zmian
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