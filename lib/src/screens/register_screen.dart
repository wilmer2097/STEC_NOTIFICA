// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'main_screen.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../main.dart';

// class RegisterScreen extends StatelessWidget {
//   const RegisterScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final TextEditingController tokenController = TextEditingController();
//     final TextEditingController userController = TextEditingController();
//     final TextEditingController passwordController = TextEditingController();

//     Future<void> registerUser() async {
//       final String token = tokenController.text.trim();
//       final String username = userController.text.trim();
//       final String password = passwordController.text.trim();

//       if (username.isEmpty || password.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Usuario y contraseña son obligatorios")),
//         );
//         return;
//       }

//       // Obtener automáticamente el token FCM
//       final String fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

//       // Definir la URL de la API
//       final Uri apiUrl = Uri.parse("https://biblioteca1.info/fly2w/registertUser.php");

//       try {
//         final response = await http.post(apiUrl, body: {
//           "action": "register",
//           "username": username,
//           "password": password,
//           "token": token,
//           "fcm_token": fcmToken,
//         });

//         // Imprimir la respuesta del API en la consola
//         print("API Response: ${response.body}");

//         if (response.statusCode == 200) {
//           final Map<String, dynamic> data = json.decode(response.body);
//           if (data["status"] == "success") {
//             // Guardar los datos en SharedPreferences
//             final SharedPreferences prefs = await SharedPreferences.getInstance();
//             prefs.setString("userData", json.encode(data["data"]));

//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const MainScreen()),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(data["message"] ?? "Error en el registro")),
//             );
//           }
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Error de conexión al servidor")),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e")),
//         );
//       }
//     }

//     return Scaffold(
//       backgroundColor: fondoFormulario,
//       appBar: AppBar(
//         backgroundColor: azulVibrante,
//         title: const Text('Registrar'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Logo centrado (opcional)
//             Center(
//               child: Image.asset('lib/src/assets/logo.png', height: 80),
//             ),
//             const SizedBox(height: 32),
//             TextField(
//               controller: tokenController,
//               decoration: InputDecoration(
//                 labelText: 'Token',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: userController,
//               decoration: InputDecoration(
//                 labelText: 'Usuario',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: passwordController,
//               decoration: InputDecoration(
//                 labelText: 'Contraseña',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               obscureText: true,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size.fromHeight(50),
//                 backgroundColor: azulVibrante,
//                 foregroundColor: Colors.white,
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: registerUser,
//               child: const Text(
//                 'Guardar',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 32),
//             const Center(
//               child: Text(
//                 "Soluciones TEC © 2025",
//                 style: TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
