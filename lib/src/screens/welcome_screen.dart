// import 'package:flutter/material.dart';
// import 'login_screen.dart';
// import 'register_screen.dart';
// // Paleta de colores
// const Color blanco = Color(0xFFFFFFFF);
// const Color amarilloCrema = Color(0xFFFFE3B3);
// const Color amarilloCalido = Color(0xFFFFC973);
// const Color azulClaro = Color(0xFF30A0E0);
// const Color azulVibrante = Color(0xFF006BB9);
// const Color fondoFormulario = Color(0xFFF7F7F7);

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: blanco, // Fondo blanco
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
//           child: Column(
//             children: [
//               // Espaciado superior y logotipo centrado
//               const SizedBox(height: 32),
//               Center(
//                 child: Image.asset('lib/src/assets/logo.png', height: 120),
//               ),
//               const SizedBox(height: 48),
//               // Botón Iniciar Sesión
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(50), // Botón de ancho completo
//                   backgroundColor: azulVibrante,
//                   foregroundColor: Colors.white,
//                   elevation: 5,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const LoginScreen()),
//                   );
//                 },
//                 child: const Text(
//                   'Iniciar Sesión',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               // Botón Registrar
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(50), // Botón de ancho completo
//                   backgroundColor: azulVibrante,
//                   foregroundColor: Colors.white,
//                   elevation: 5,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const RegisterScreen()),
//                   );
//                 },
//                 child: const Text(
//                   'Registrar',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const Spacer(),
//               // Footer con leyenda
//               Text(
//                 "Soluciones TEC © 2025",
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
