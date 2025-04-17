import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Import dla Shimmer effect
import 'news_detail_screen.dart'; // <<< WAŻNE: Import ekranu szczegółów
import 'sluzba_screen.dart'; // Zakładając, że plik nazywa się sluzba_screen.dart
// <<< DODAJ IMPORT FIREBASE MESSAGING >>>
import 'package:firebase_messaging/firebase_messaging.dart';

// Upewnij się, że importujesz też inne potrzebne pliki/pakiety, jeśli są używane gdzieś indziej

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // <<< DODANO: Metoda initState do konfiguracji FCM >>>
  @override
  void initState() {
    super.initState();
    _setupFcm(); // Wywołaj konfigurację FCM przy starcie ekranu
  }

  // <<< DODANO: Funkcja konfigurująca FCM >>>
  Future<void> _setupFcm() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Poproś o uprawnienia (iOS wymaga tego jawnie, Android >= 13 też)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, announcement: false, badge: true, carPlay: false,
      criticalAlert: false, provisional: false, sound: true,
    );

    print('[FCM] User granted permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      print('[FCM] User declined or has not accepted permission');
      // Można pokazać dialog informujący o braku zgody
    }

    // 2. Pobierz token FCM
    String? token = await messaging.getToken();
    print("[FCM] Firebase Messaging Token: $token");

    // TODO: Zapisz token w bazie danych powiązany z użytkownikiem
    if (token != null) {
      _saveTokenToDatabase(token);
    }

    // 3. Nasłuchuj na odświeżenie tokena
    messaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // 4. Nasłuchuj na wiadomości przychodzące, gdy apka jest na pierwszym planie
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] Got a message whilst in the foreground!');
      print('[FCM] Message data: ${message.data}');

      if (message.notification != null) {
        print('[FCM] Message also contained a notification: ${message.notification?.title}');
        // Pokaż powiadomienie w aplikacji (np. dialog)
        if (mounted) { // Sprawdź czy widget jest nadal zamontowany
           showDialog(
             context: context,
             builder: (context) => AlertDialog(
               title: Text(message.notification?.title ?? 'Nowe powiadomienie'),
               content: Text(message.notification?.body ?? ''),
               actions: [ TextButton( onPressed: () => Navigator.of(context).pop(), child: const Text('OK'), ), ],
             ),
           );
        }
      }
    });

    // 5. Obsługa kliknięcia w powiadomienie, gdy aplikacja jest w tle lub zamknięta
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('[FCM] App opened from terminated state by notification: ${initialMessage.messageId}');
      _handleMessageTap(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  // <<< DODANO: Funkcja zapisu tokena (placeholder/przykład) >>>
  Future<void> _saveTokenToDatabase(String? token) async {
    if (token == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    print("[FCM] Saving token for user $userId");
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
      print("[FCM] Token saved successfully.");
    } catch (e) {
      print("[FCM] Error saving token: $e");
    }
  }

  // <<< DODANO: Funkcja obsługi kliknięcia powiadomienia (placeholder) >>>
  void _handleMessageTap(RemoteMessage message) {
    print('[FCM] Notification tapped! Message ID: ${message.messageId}');
    print('[FCM] Message data: ${message.data}');
    // TODO: Zaimplementuj logikę nawigacji lub inną akcję
    // na podstawie message.data
    // np. if (message.data['screen'] == 'newsDetail') { ... }
  }


  // Funkcja wywoływana przez RefreshIndicator (bez zmian)
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() { });
    }
  }

  // Funkcja budująca placeholder Shimmer (bez zmian)
  Widget _buildNewsItemShimmer(BuildContext context) {
    return Container( margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), padding: const EdgeInsets.all(16.0), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(15.0), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2), ), ], ), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Container( width: double.infinity, height: 150.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(10.0), ), ), const SizedBox(height: 12), Container( width: double.infinity, height: 20.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 8), Container( width: double.infinity, height: 14.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 6), Container( width: MediaQuery.of(context).size.width * 0.7, height: 14.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 12), Align( alignment: Alignment.centerRight, child: Container( width: 100.0, height: 12.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), ), ], ), );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Logika pobierania imienia (bez zmian)
    String welcomeName = "Użytkowniku";
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) { final nameParts = displayName.split(' '); if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) { welcomeName = nameParts[0]; } else { welcomeName = displayName; } } else if (user?.email != null && user!.email!.isNotEmpty) { welcomeName = user.email!; }

    // Definicja gradientów dla kafelków (zgodnie z Twoim kodem)
    final gradientPairs = [
       [const Color.fromARGB(255, 109, 196, 223), const Color.fromARGB(255, 133, 221, 235)],
    ];

    // Funkcja budująca logo (bez zmian)
    Widget buildLogo(double height) { return Image.asset( 'assets/logo.png', height: height, errorBuilder: (context, error, stackTrace) { print("Błąd ładowania logo: $error"); return Icon(Icons.image_not_supported, size: height, color: Colors.grey); }, ); }

    // --- Początek definicji Scaffold ---
    return Scaffold(
      backgroundColor: Colors.white, // Białe tło

      // AppBar (zgodnie z Twoim kodem: białe tło, logo w actions)
      appBar: AppBar(
        title: const Text('Panel Główny'),
        flexibleSpace: Container( decoration: BoxDecoration( color:Colors.white ), ),
        actions: [ Padding( padding: const EdgeInsets.only(right: 16.0), child: buildLogo(50), ), ], // Logo w AppBar miało wysokość 50 w Twoim kodzie
      ),

     // --- Początek definicji Drawer ---
      drawer: Drawer(
         child: ListView(
           padding: EdgeInsets.zero,
           children: [
             // DrawerHeader (bez zmian)
             DrawerHeader(
               padding: EdgeInsets.zero,
               decoration: BoxDecoration(
                 color: Colors.white,
               ),
               child: Stack(
                 children: <Widget>[
                   Align(
                     alignment: Alignment.topCenter,
                     child: Padding(
                       padding: const EdgeInsets.only(top: 16.0),
                       child: buildLogo(100),
                     ),
                   ),
                   Positioned(
                     bottom: 12.0,
                     left: 16.0,
                     child: Text(
                       "Witaj, $welcomeName",
                       style: const TextStyle(
                         color: Colors.black,
                         fontSize: 18,
                       ),
                     ),
                   ),
                 ],
               ),
             ),

             // --- ZMIANA KOLEJNOŚCI ---

             // 1. "Służba" (jest teraz jako pierwszy element po nagłówku)
             ListTile(
               leading: const Icon(Icons.volunteer_activism_outlined),
               title: const Text("Służba"),
               onTap: () {
                 Navigator.pop(context); // Zamknij szufladę
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const SluzbaScreen()),
                 );
               },
             ),

             // 2. "Ustawienia" (przeniesione pod "Służba")
             const ListTile(
               leading: Icon(Icons.settings),
               title: Text("Ustawienia"),
               // onTap: () { Navigator.pop(context); /* Logika Ustawień */},
             ),

             // 3. "Wyloguj" (pozostaje na końcu)
             ListTile(
               leading: const Icon(Icons.logout),
               title: const Text("Wyloguj"),
               onTap: () async {
                 Navigator.pop(context);
                 await FirebaseAuth.instance.signOut();
               },
             ),
             // --- KONIEC ZMIANY KOLEJNOŚCI ---
           ],
         ),
      ),
      // --- Koniec definicji Drawer ---

      // Body (zgodnie z Twoim kodem: StreamBuilder, lista kafelków z gradientem i białym tekstem)
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Text("Witaj, $welcomeName 👋", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), ),
             Padding( padding: const EdgeInsets.only(bottom: 10.0), child: Text("Aktualności", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)), ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: Theme.of(context).primaryColor,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance .collection('aktualnosci') .orderBy('publishDate', descending: true) .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) { return ListView.builder(itemCount: 5, itemBuilder: (context, index) => Shimmer.fromColors( baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: _buildNewsItemShimmer(context), ),); }
                    if (snapshot.hasError) { print("Błąd Firestore: ${snapshot.error}"); return Center(child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height: 10), const Text('Nie można załadować aktualności.'), const SizedBox(height: 10), ElevatedButton( onPressed: _handleRefresh, child: const Text('Spróbuj ponownie'), ) ], )); }
                    final docs = snapshot.data?.docs;
                    if (docs == null || docs.isEmpty) { return Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.newspaper_outlined, color: Colors.grey[400], size: 60), const SizedBox(height: 10), Text("Brak aktualności.", style: TextStyle(color: Colors.grey[600])), ], )); }
                    // Lista aktualności
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox.shrink();
                        final title = data['title'] as String? ?? "Bez tytułu";
                        final content = data['content'] as String? ?? "Brak treści";
                        final timestamp = data['publishDate'] as Timestamp?;
                        final imageUrl = data['imageUrl'] as String?;
                        final gradientPair = gradientPairs[index % gradientPairs.length];
                        final formattedDateForList = timestamp != null ? DateFormat('dd.MM.yyyy HH:mm', 'pl_PL').format(timestamp.toDate()) : 'Brak daty';

                        // Kafelek InkWell
                        return InkWell(
                          onTap: () { Navigator.push( context, MaterialPageRoute( builder: (context) => NewsDetailScreen( title: title, content: content, timestamp: timestamp, imageUrl: imageUrl, ), ), ); },
                          borderRadius: BorderRadius.circular(15.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration( gradient: LinearGradient( colors: gradientPair, begin: Alignment.topLeft, end: Alignment.bottomRight, ), borderRadius: BorderRadius.circular(15.0), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2), ), ], ),
                            child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (imageUrl != null && Uri.tryParse(imageUrl)?.isAbsolute == true) Padding( padding: const EdgeInsets.only(bottom: 12.0), child: ClipRRect( borderRadius: BorderRadius.circular(10.0), child: Image.network( imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) return child; return Container( height: 150, decoration: BoxDecoration( color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.0), ), child: Center(child: CircularProgressIndicator( value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: Colors.white70, )), ); }, errorBuilder: (context, error, stackTrace) { print("Błąd ładowania obrazka na liście: $error"); return Container( height: 150, decoration: BoxDecoration( color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.0), ), child: const Center(child: Icon(Icons.broken_image, color: Colors.white70, size: 40)), ); }, ), ), ),
                                // Tekst na kafelkach (zgodnie z Twoim kodem - biały)
                                Text( title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white), ),
                                const SizedBox(height: 8),
                                Text( content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4, color: Colors.white.withOpacity(0.9)), maxLines: 4, overflow: TextOverflow.ellipsis, ),
                                const SizedBox(height: 12),
                                Align( alignment: Alignment.centerRight, child: Text( 'Opublikowano: $formattedDateForList', style: Theme.of(context).textTheme.bodySmall?.copyWith( color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic), ), ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ), // Koniec Body
    ); // Koniec Scaffold
  } // Koniec build()
} // Koniec _HomeScreenState