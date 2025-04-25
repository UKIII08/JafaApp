import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Importy ekranów
import 'news_detail_screen.dart';
import 'sluzba_screen.dart';
import 'multimedia_screen.dart';
import 'wydarzenia_navigator_screen.dart';
import 'wsparcie_screen.dart';
import 'informacje_screen.dart';
import 'library_screen.dart'; // <<< DODANO IMPORT EKRANU BIBLIOTEKI >>>

// Importy pomocnicze
import '../widgets/glowing_card_wrapper.dart'; // Import wrappera

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  // --- Logika FCM (bez zmian) ---
  Future<void> _setupFcm() async {
    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission( alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true, );
    print('[FCM] User granted permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus != AuthorizationStatus.authorized && settings.authorizationStatus != AuthorizationStatus.provisional) { print('[FCM] User declined or has not accepted permission'); }
    String? token = await messaging.getToken(); print("[FCM] Firebase Messaging Token: $token"); if (token != null) { _saveTokenToDatabase(token); } messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) { print('[FCM] Got a message whilst in the foreground!'); print('[FCM] Message data: ${message.data}'); if (message.notification != null) { print('[FCM] Message also contained a notification: ${message.notification?.title}'); if (mounted) { showDialog( context: context, builder: (context) => AlertDialog( title: Text(message.notification?.title ?? 'Nowe powiadomienie'), content: Text(message.notification?.body ?? ''), actions: [ TextButton( onPressed: () => Navigator.of(context).pop(), child: const Text('OK'), ), ], ), ); } } });
    RemoteMessage? initialMessage = await messaging.getInitialMessage(); if (initialMessage != null) { print('[FCM] App opened from terminated state by notification: ${initialMessage.messageId}'); _handleMessageTap(initialMessage); } FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }
  Future<void> _saveTokenToDatabase(String? token) async { if (token == null) return; final userId = FirebaseAuth.instance.currentUser?.uid; if (userId == null) return; print("[FCM] Saving token for user $userId"); try { await FirebaseFirestore.instance.collection('users').doc(userId).set({ 'fcmTokens': FieldValue.arrayUnion([token]), }, SetOptions(merge: true)); print("[FCM] Token saved successfully."); } catch (e) { print("[FCM] Error saving token: $e"); } }
  void _handleMessageTap(RemoteMessage message) { print('[FCM] Notification tapped! Message ID: ${message.messageId}'); print('[FCM] Message data: ${message.data}'); /* TODO: Implement navigation based on message data */ }
  // --- Koniec logiki FCM ---

  // Funkcja RefreshIndicator (bez zmian)
  Future<void> _handleRefresh() async { await Future.delayed(const Duration(seconds: 1)); if (mounted) { setState(() { }); } }

  // Funkcja Shimmer (bez zmian)
  Widget _buildNewsItemShimmer(BuildContext context) { return Container( margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), padding: const EdgeInsets.all(16.0), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(15.0), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2), ), ], ), child: Shimmer.fromColors( baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Container( width: double.infinity, height: 150.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(10.0), ), ), const SizedBox(height: 12), Container( width: double.infinity, height: 20.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 8), Container( width: double.infinity, height: 14.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 6), Container( width: MediaQuery.of(context).size.width * 0.7, height: 14.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 12), Align( alignment: Alignment.centerRight, child: Container( width: 100.0, height: 12.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), ), ], ), ), ); }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Lepsze pobieranie imienia powitalnego
    String welcomeName = "Użytkowniku";
    if (user != null) {
       final displayName = user.displayName?.trim();
       if (displayName != null && displayName.isNotEmpty) {
          final nameParts = displayName.split(' ');
          welcomeName = nameParts.first.isNotEmpty ? nameParts.first : displayName;
       } else if (user.email != null && user.email!.isNotEmpty) {
          welcomeName = user.email!;
       }
    }


    // GradientPairs (bez zmian)
    final gradientPairs = [ [const Color.fromARGB(255, 109, 196, 223), const Color.fromARGB(255, 133, 221, 235)], ];

    // Funkcja buildLogo (bez zmian)
    Widget buildLogo(double height) { return Image.asset( 'assets/logo.png', height: height, errorBuilder: (context, error, stackTrace) { print("Błąd ładowania logo: $error"); return Icon(Icons.image_not_supported, size: height, color: Colors.grey); }, ); }

    // Definicje kolorów dla gradientu (bez zmian)
    const Color offWhiteColor = Color(0xFFFAFAFA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Główny'),
        actions: [ Padding( padding: const EdgeInsets.only(right: 16.0), child: buildLogo(50), ), ],
      ),

      // --- DRAWER ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              decoration: null, // Usuwamy dekorację, bo używamy AnimatedMeshGradient
              child: AnimatedMeshGradient(
                colors: const [
                  Colors.white,
                  offWhiteColor,
                  Color.fromARGB(255, 57, 219, 244),
                  Colors.white,
                ],
                options: AnimatedMeshGradientOptions(),
                child: Stack(
                  children: <Widget>[
                    Align( alignment: Alignment.topCenter, child: Padding( padding: const EdgeInsets.only(top: 16.0), child: buildLogo(100), ), ),
                    Positioned( bottom: 12.0, left: 16.0, child: Text( "Witaj, $welcomeName", style: const TextStyle( color: Colors.black87, // Ciemniejszy dla lepszego kontrastu
                      fontSize: 18, fontWeight: FontWeight.w500, // Lekko pogrubiony
                      shadows: [ Shadow( blurRadius: 1.0, color: Colors.black12, offset: Offset(0.5, 0.5), ), ], ), ), ),
                  ],
                ),
              ),
            ),
            // --- Elementy menu ---
            ListTile( leading: const Icon(Icons.volunteer_activism_outlined), title: const Text("Służba"), onTap: () { Navigator.pop(context); Navigator.push( context, MaterialPageRoute(builder: (context) => const SluzbaScreen()), ); }, ),
            ListTile( leading: const Icon(Icons.photo_library_outlined), title: const Text("Multimedia"), onTap: () { Navigator.pop(context); Navigator.push( context, MaterialPageRoute(builder: (context) => const MultimediaScreen()), ); }, ),
            ListTile( leading: const Icon(Icons.event_available_outlined), title: const Text("Wydarzenia"), onTap: () { Navigator.pop(context); Navigator.push( context, MaterialPageRoute(builder: (context) => const MainWydarzeniaNavigatorScreen()), ); }, ),

            // <<< NOWA POZYCJA MENU: BIBLIOTEKA >>>
            ListTile(
              leading: const Icon(Icons.local_library_outlined), // Ikona biblioteki
              title: const Text("Biblioteka"),
              onTap: () {
                Navigator.pop(context); // Zamknij szufladę
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LibraryScreen()), // Przejdź do LibraryScreen
                );
              },
            ),
            // <<< KONIEC NOWEJ POZYCJI MENU >>>

            ListTile( leading: const Icon(Icons.favorite_border_outlined), title: const Text("Wsparcie"), onTap: () { Navigator.pop(context); Navigator.push( context, MaterialPageRoute(builder: (context) => const WsparcieScreen()), ); }, ),
            ListTile( leading: const Icon(Icons.info_outline), title: const Text("Informacje"), onTap: () { Navigator.pop(context); Navigator.push( context, MaterialPageRoute(builder: (context) => const InformacjeScreen()), ); }, ),
            const Divider(), // Separator przed Wyloguj
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Wyloguj"),
              onTap: () async {
                Navigator.pop(context);
                // Opcjonalnie: Można dodać dialog potwierdzający
                await FirebaseAuth.instance.signOut();
                // AuthWrapper automatycznie przeniesie do ekranu logowania
              },
            ),
          ],
        ),
      ),
      // --- Koniec Drawer ---

      // --- Body (z GlowingCardWrapper dla aktualności) ---
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
                  stream: FirebaseFirestore.instance
                      .collection('aktualnosci')
                      .orderBy('publishDate', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Używamy poprawionego Shimmera
                      return ListView.builder(
                          itemCount: 3, // Mniej elementów dla shimmera
                          itemBuilder: (context, index) => _buildNewsItemShimmer(context),
                      );
                    }
                    if (snapshot.hasError) {
                       print("Błąd StreamBuilder (Aktualności): ${snapshot.error}");
                       return Center(child: Text('Błąd ładowania aktualności: ${snapshot.error}'));
                    }
                    final docs = snapshot.data?.docs;
                    if (docs == null || docs.isEmpty) {
                       return const Center(child: Text('Brak aktualności.'));
                    }

                    // Lista aktualności
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                         final data = docs[index].data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox.shrink(); // Pomiń, jeśli dane są nullem

                        final title = data['title'] as String? ?? "Bez tytułu";
                        final content = data['content'] as String? ?? "Brak treści";
                        final timestamp = data['publishDate'] as Timestamp?;
                        final imageUrl = data['imageUrl'] as String?;
                        // Wybierz parę gradientu
                        final gradientPair = gradientPairs[index % gradientPairs.length];
                        // Bezpieczne formatowanie daty
                        final String formattedDateForList = timestamp != null
                            ? DateFormat('dd.MM.yyyy HH:mm', 'pl_PL').format(timestamp.toDate())
                            : 'Brak daty';

                        // Zastosowanie GlowingCardWrapper wokół kontenera z gradientem
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GlowingCardWrapper(
                            borderRadius: BorderRadius.circular(15.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push( context, MaterialPageRoute( builder: (context) => NewsDetailScreen( title: title, content: content, timestamp: timestamp, imageUrl: imageUrl, ), ), );
                              },
                              borderRadius: BorderRadius.circular(15.0),
                              child: Container( // Kontener wewnętrzny
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientPair, // Używamy pary gradientu
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Obrazek (z lepszą obsługą ładowania i błędów)
                                    if (imageUrl != null && Uri.tryParse(imageUrl)?.isAbsolute == true)
                                       Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: ClipRRect(
                                             borderRadius: BorderRadius.circular(10.0),
                                             child: Image.network(
                                                imageUrl,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                   if (loadingProgress == null) return child;
                                                   // Prosty placeholder z CircularProgressIndicator
                                                   return Container(
                                                      height: 150,
                                                      decoration: BoxDecoration( color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.0), ),
                                                      child: Center(child: CircularProgressIndicator( value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: Colors.white70, strokeWidth: 2, )),
                                                   );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                   print("Błąd ładowania obrazka na liście: $error");
                                                   // Placeholder błędu
                                                   return Container( height: 150, decoration: BoxDecoration( color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.0), ), child: const Center(child: Icon(Icons.broken_image, color: Colors.white70, size: 40)), );
                                                },
                                             ),
                                          ),
                                       ),
                                    // Tekst (biały dla lepszego kontrastu na gradiencie)
                                    Text( title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white), ),
                                    const SizedBox(height: 8),
                                    Text( content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4, color: Colors.white.withOpacity(0.9)), maxLines: 4, overflow: TextOverflow.ellipsis, ),
                                    const SizedBox(height: 12),
                                    // Data publikacji
                                    Align( alignment: Alignment.centerRight, child: Text( 'Opublikowano: $formattedDateForList', style: Theme.of(context).textTheme.bodySmall?.copyWith( color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic), ), ),
                                  ],
                                ),
                              ),
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
