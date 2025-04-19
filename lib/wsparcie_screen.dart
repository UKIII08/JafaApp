// lib/screens/wsparcie_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Potrzebne do obsługi schowka (Clipboard)

class WsparcieScreen extends StatelessWidget {
  const WsparcieScreen({super.key});

  // --- Zmień poniższe dane na prawdziwe! ---
  final String bankName = "Nazwa Twojego Banku"; // Opcjonalne, można usunąć jeśli niepotrzebne
  final String recipientName = "Fundacja Jafa"; // Ważne dla przelewu
  final String accountNumber = "PL 11 2222 3333 4444 5555 6666 7777"; // Wstaw poprawny numer konta!
  final String transferTitleSuggestion = "Darowizna na cele statutowe XYZ"; // Sugerowany tytuł, ułatwia księgowanie
  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Usuwamy spacje z numeru konta na potrzeby kopiowania
    final String accountNumberForClipboard = accountNumber.replaceAll(' ', '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wsparcie'),
      ),
      // Używamy SingleChildScrollView, gdyby treść była dłuższa niż ekran
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Główny nagłówek
            Text(
              'Wesprzyj naszą działalność',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary, // Użyj koloru z motywu
                  ),
            ),
            const SizedBox(height: 16),

            // Tekst wprowadzający (dostosuj treść)
            Text(
              'Twoja hojność i wsparcie finansowe pozwalają nam kontynuować i rozwijać naszą misję. Każda, nawet najmniejsza wpłata, jest dla nas cenna i pomaga w realizacji naszych celów. Z serca dziękujemy!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 30),

            // Podtytuł sekcji danych do przelewu
             Text(
               'Dane do przelewu tradycyjnego:',
               style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
             ),
            const SizedBox(height: 20),

            // Wyświetlenie danych w czytelny sposób
            _buildInfoCard(context, recipientName, accountNumber, transferTitleSuggestion, accountNumberForClipboard),

            const SizedBox(height: 30),

            // Podziękowanie na dole
             Center(
               child: Text(
                 'Dziękujemy za Twoje wsparcie!',
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
                   fontStyle: FontStyle.italic,
                   color: Colors.grey[700]
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
          ],
        ),
      ),
    );
  }

  // Helper widget do wyświetlania danych w ramce dla lepszej czytelności
  Widget _buildInfoCard(BuildContext context, String recipient, String account, String titleSuggestion, String accountForClipboard) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, Icons.person_outline, "Odbiorca:", recipient),
            const Divider(height: 24),
            _buildAccountNumberRow(context, account, accountForClipboard), // Używamy dedykowanej funkcji dla numeru konta
            const Divider(height: 24),
             _buildInfoRow(context, Icons.title, "Sugerowany tytuł:", titleSuggestion),
          ],
        ),
      ),
    );
  }

  // Helper widget dla zwykłych wierszy informacyjnych
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 2),
              // Umożliwia zaznaczenie tekstu (np. odbiorcy, tytułu)
              SelectableText(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

   // Helper widget specjalnie dla numeru konta z przyciskiem kopiowania
   Widget _buildAccountNumberRow(BuildContext context, String accountNumberDisplay, String accountNumberClipboard) {
     return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.grey[600]), // Ikona portfela/konta
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("Numer konta (IBAN):", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
               const SizedBox(height: 2),
               // SelectableText pozwala łatwo zaznaczyć numer konta
               SelectableText(
                 accountNumberDisplay, // Wyświetlamy wersję ze spacjami
                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontFamily: 'monospace', // Dobra czcionka dla numerów
                   letterSpacing: 1.1, // Lekki odstęp między znakami
                 ),
               ),
            ],
          ),
        ),
        // Przycisk Kopiowania
        IconButton(
          icon: const Icon(Icons.copy_all_outlined), // Ikona kopiowania
          iconSize: 22,
          tooltip: 'Skopiuj numer konta',
          color: Theme.of(context).colorScheme.primary, // Kolor przycisku
          // Zmniejszamy domyślny padding IconButtona, by był bliżej tekstu
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.only(left: 12.0), // Dodajemy padding tylko z lewej
          splashRadius: 24, // Zmniejszamy promień "plusknięcia"
          onPressed: () {
            // Kopiowanie do schowka wersji bez spacji
            Clipboard.setData(ClipboardData(text: accountNumberClipboard));
            // Pokaż potwierdzenie
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Numer konta skopiowany do schowka!'),
                duration: Duration(seconds: 2), // Krótszy czas wyświetlania
              ),
            );
          },
        ),
      ],
    );
   }
}