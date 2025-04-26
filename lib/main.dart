// main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';

import 'src/providers/push_notifications_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/main_screen.dart';

const Color blanco = Color(0xFFFFFFFF);
const Color azulVibrante = Color(0xFF006BB9);
const Color fondoFormulario = Color(0xFFF7F7F7);

final pushNotificationsProvider = PushNotificationsProvider();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await pushNotificationsProvider.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isLoggedIn() async {
    bool isValid = false;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');

      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = json.decode(contents);
        final userId = data["userId"];

        if (userId != null && userId.toString().isNotEmpty) {
          isValid = true;
        }
      }
    } catch (_) {
      // Ignorar errores y retornar false
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'STEC Notifica',
      theme: ThemeData(
        primaryColor: azulVibrante,
        scaffoldBackgroundColor: blanco,
        appBarTheme: const AppBarTheme(
          backgroundColor: azulVibrante,
          foregroundColor: blanco,
        ),
      ),
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}