import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Import dla Shimmer effect
import 'news_detail_screen.dart'; // <<< WAŻNE: Import ekranu szczegółów

// Upewnij się, że importujesz też inne potrzebne pliki/pakiety, jeśli są używane gdzieś indziej

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Funkcja wywoływana przez RefreshIndicator
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() { });
    }
  }

  // Funkcja budująca pojedynczy placeholder (szkielet) dla efektu shimmer
  Widget _buildNewsItemShimmer(BuildContext context) {
    // ... (bez zmian z Twojego kodu) ...
    return Container( margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), padding: const EdgeInsets.all(16.0), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(15.0), boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2), ), ], ), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Container( width: double.infinity, height: 150.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(10.0), ), ), const SizedBox(height: 12), Container( width: double.infinity, height: 20.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 8), Container( width: double.infinity, height: 14.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 6), Container( width: MediaQuery.of(context).size.width * 0.7, height: 14.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), const SizedBox(height: 12), Align( alignment: Alignment.centerRight, child: Container( width: 100.0, height: 12.0, decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(4.0), ), ), ), ], ), );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // --- Logika pobierania tylko IMIENIA ---
    String welcomeName = "Użytkowniku";
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) { final nameParts = displayName.split(' '); if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) { welcomeName = nameParts[0]; } else { welcomeName = displayName; } } else if (user?.email != null && user!.email!.isNotEmpty) { welcomeName = user.email!; }
    // --- Koniec logiki imienia ---

    // Definiujemy pary kolorów dla gradientów kafelków aktualności
    final gradientPairs = [
       [const Color.fromARGB(255, 109, 196, 223), const Color.fromARGB(255, 133, 221, 235)], // Niebieski z Twojego kodu
       // Możesz dodać tu więcej gradientów
    ];

    // --- Widget logo do użycia w AppBar i Drawer ---
    Widget buildLogo(double height) {
      return Image.asset(
        'assets/logo.png', // <<< ŚCIEŻKA DO TWOJEGO LOGO
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print("Błąd ładowania logo: $error");
          return Icon(Icons.image_not_supported, size: height, color: Colors.grey);
        },
      );
    }

    // --- Początek definicji Scaffold ---
    return Scaffold(
      // --- ZMIANA: Przywrócenie białego tła Scaffold ---
      backgroundColor: Colors.white,

      // --- Początek AppBar ---
      appBar: AppBar(
        title: const Text('Panel Główny'),
        flexibleSpace: Container( // Gradient dla AppBar
          decoration: BoxDecoration(
            color:Colors.white
             // --- ZMIANA: Przywrócenie gradientu w AppBar ---
          ),
        ),
        // --- ZMIANA: Dodanie logo do AppBar ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Odstęp od prawej krawędzi
            child: buildLogo(50), // Logo w AppBar
          ),
        ],
      ),
      // --- Koniec AppBar ---

      // --- Początek definicji Drawer ---
      drawer: Drawer(
         child: ListView(
           padding: EdgeInsets.zero,
           children: [
             // --- ZMIANA: DrawerHeader używający Stack ---
             DrawerHeader(
               padding: EdgeInsets.zero, // Usuwamy padding nagłówka
               decoration: BoxDecoration(
                 color: Colors.white, // Białe tło
               ),
               child: Stack( // Używamy Stack do pozycjonowania
                 children: <Widget>[
                   Align(
                     alignment: Alignment.topCenter, // Wyrównaj do GÓRY i ŚRODKA poziomo
                     child: Padding(
                       padding: const EdgeInsets.only(top: 16.0), // Dodaj odstęp od góry
                       child: buildLogo(100), // Twoje logo (rozmiar z poprzedniego kroku)
                     ),
                   ),
                   // --- Koniec zmiany dla logo ---
                   // Tekst powitalny w lewym dolnym rogu
                   Positioned(
                     bottom: 12.0,
                     left: 16.0,
                     child: Text(
                       "Witaj, $welcomeName",
                       style: const TextStyle(
                         color: Colors.black, // Czarny tekst
                         fontSize: 18,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
             // --- Reszta elementów szuflady (bez zmian z Twojego kodu) ---
             const ListTile( leading: Icon(Icons.settings), title: Text("Ustawienia"), /* onTap: (){} */ ),
             ListTile( leading: const Icon(Icons.logout), title: const Text("Wyloguj"), onTap: () async { Navigator.pop(context); await FirebaseAuth.instance.signOut(); }, ),
           ],
         ),
      ),
      // --- Koniec definicji Drawer ---

      // --- Początek definicji Body (bez zmian logiki wewnętrznej z Twojego kodu) ---
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
                    if (snapshot.connectionState == ConnectionState.waiting) { /* ... Shimmer ... */
                      return ListView.builder(itemCount: 5, itemBuilder: (context, index) => Shimmer.fromColors( baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: _buildNewsItemShimmer(context), ),);
                    }
                    if (snapshot.hasError) { /* ... Error message ... */
                       print("Błąd Firestore: ${snapshot.error}"); return Center(child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height: 10), const Text('Nie można załadować aktualności.'), const SizedBox(height: 10), ElevatedButton( onPressed: _handleRefresh, child: const Text('Spróbuj ponownie'), ) ], ));
                    }
                    final docs = snapshot.data?.docs;
                    if (docs == null || docs.isEmpty) { /* ... No data message ... */
                       return Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.newspaper_outlined, color: Colors.grey[400], size: 60), const SizedBox(height: 10), Text("Brak aktualności.", style: TextStyle(color: Colors.grey[600])), ], ));
                    }
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
                                // --- ZMIANA: Przywrócenie białego tekstu na kafelkach ---
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