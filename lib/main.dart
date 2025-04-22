import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:flutter/foundation.dart';

import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

Future<void> _createOrUpdateUserDocument(User user) async {
  final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final timestamp = FieldValue.serverTimestamp();

  try {
    final docSnapshot = await userDocRef.get();
    Map<String, dynamic> dataToSet = {
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'lastLogin': timestamp,
    };
    if (!docSnapshot.exists) {
      dataToSet['createdAt'] = timestamp;
      dataToSet['roles'] = [];
      dataToSet['fcmTokens'] = [];
    }
    await userDocRef.set(dataToSet, SetOptions(merge: true));
    print("Dokument użytkownika stworzony/zaktualizowany dla ${user.uid}");
  } catch (e) {
    print("Błąd podczas tworzenia/aktualizacji dokumentu użytkownika: $e");
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  if (message.notification != null) {
    print(
        'Message also contained a notification: ${message.notification?.title} / ${message.notification?.body}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pl_PL', null);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicjalizacja Firebase Admin SDK (tylko na platformach innych niż web)
  if (!kIsWeb) {
    try {
      FirebaseAdmin.instance.initializeApp();
      print("Firebase Admin SDK initialized successfully");
    } catch (e) {
      print("Error initializing Firebase Admin SDK: $e");
    }
  } else {
    print("Firebase Admin SDK initialization skipped on web platform");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color seedColor = Color.fromARGB(255, 109, 196, 223);

    return MaterialApp(
      title: 'Jafa App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.senTextTheme(
            ThemeData(brightness: Brightness.light).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1.0,
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(
              body: Center(
                  child: Text('Wystąpił błąd podczas sprawdzania logowania.')));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<List<String>>(
            future: _getUserRoles(user.uid),
            builder: (context, rolesSnapshot) {
              if (rolesSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (rolesSnapshot.hasError) {
                print('Błąd pobierania ról: ${rolesSnapshot.error}');
                return const HomeScreen();
              }
              final userRoles = rolesSnapshot.data ?? [];
              _createOrUpdateUserDocument(user);

              if (userRoles.contains('Admin')) {
                return const AdminScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Future<List<String>> _getUserRoles(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final roles = data?['roles'] as List<dynamic>?;
        return roles?.cast<String>().toList() ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('Błąd pobierania ról dla $userId: $e');
      return [];
    }
  }
}