// lib/screens/multimedia_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Potrzebny do otwierania linków

class MultimediaScreen extends StatelessWidget {
  const MultimediaScreen({super.key});

  // --- !!! WAŻNE: UPEWNIJ SIĘ, ŻE TO JEST TWÓJ POPRAWNY LINK !!! ---
  // Ten link musi prowadzić do folderu na Twoim Dysku Google,
  // który udostępniłeś z odpowiednimi uprawnieniami (np. Edytor dla każdego z linkiem).
  static const String _googleDriveFolderUrl = "https://drive.google.com/drive/folders/1a4pWbwSxNxWmpPHD6747CXXfdIbpvPZA?usp=sharing";

  // Oryginalny tekst zastępczy do porównania
  static const String _placeholderUrl = "TUTAJ_WKLEJ_LINK_DO_FOLDERU_GOOGLE_DRIVE";


  // Funkcja pomocnicza do otwierania URL
  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Błąd otwierania URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie można otworzyć linku: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Multimedia"),
        backgroundColor: Colors.white, // Białe tło AppBar
        foregroundColor: Colors.black, // Ciemne ikony/tekst na białym tle
        elevation: 1.0, // Subtelny cień
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center( // Wycentrowanie zawartości
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Wycentruj w pionie
            crossAxisAlignment: CrossAxisAlignment.center, // Wycentruj w poziomie
            children: [
              Icon(
                Icons.folder_shared_outlined, // Ikona folderu
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                "Wspólny Folder Zdjęć",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Kliknij przycisk poniżej, aby otworzyć folder na Dysku Google. Możesz tam przeglądać zdjęcia z wydarzeń oraz dodawać własne.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Ostrzeżenie o bezpieczeństwie
              // Sprawdzamy, czy link jest inny niż placeholder (czyli został zmieniony)
              if (_googleDriveFolderUrl.isNotEmpty && _googleDriveFolderUrl != _placeholderUrl)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Pamiętaj: bądź odpowiedzialny za treści, które dodajesz.",
                    style: TextStyle(fontSize: 13, color: Colors.orange[800], fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text("Otwórz folder ze zdjęciami"),
                // --- POPRAWIONA LOGIKA onPressed ---
                onPressed: () {
                  // Sprawdź, czy link nie jest pusty i czy NIE JEST placeholderem
                  if (_googleDriveFolderUrl.isNotEmpty && _googleDriveFolderUrl != _placeholderUrl) {
                    // Jeśli link jest poprawnie wstawiony, otwórz go
                    _launchURL(_googleDriveFolderUrl, context);
                  } else {
                    // Jeśli link nadal jest placeholderem lub jest pusty, pokaż informację
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link do folderu nie został jeszcze skonfigurowany w kodzie aplikacji.')),
                    );
                  }
                },
                // --- KONIEC POPRAWKI onPressed ---
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}