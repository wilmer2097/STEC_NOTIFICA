import 'dart:convert';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de login
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();

  // Variables para el logo
  String _logoLink = ""; // URL obtenida de la base de datos (var_descripcion)
  String _localLogoVersion = "0"; // Versión local (guardada en 'logo_variable.json')

  @override
  void initState() {
    super.initState();
    _loadLocalLogoVariable().then((localVer) {
      _localLogoVersion = localVer ?? "0";
      _checkAndUpdateLogo();
    });
  }

  // Lee el archivo local "logo_variable.json" para obtener la versión del logo
  Future<String?> _loadLocalLogoVariable() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/logo_variable.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return data["url_logo_version"]?.toString();
      }
    } catch (e) {
      print("Error leyendo variable local del logo: $e");
    }
    return null;
  }

  // Escribe la versión del logo en "logo_variable.json"
  Future<void> _writeLocalLogoVariable(String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/logo_variable.json');
      Map<String, dynamic> data = {"url_logo_version": value};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error escribiendo variable local del logo: $e");
    }
  }

  /// Función para escribir los datos del usuario en "user_data.json"
  Future<void> _writeLocalUserData(Map<String, dynamic> userData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');
      await file.writeAsString(jsonEncode(userData));
      print("Datos del usuario guardados localmente.");
    } catch (e) {
      print("Error escribiendo datos locales del usuario: $e");
    }
  }

  /// Consulta el endpoint para obtener la variable "url_logo".
  /// Solo actualiza si el valor remoto (convertido a entero) es mayor que el valor local.
  Future<void> _checkAndUpdateLogo() async {
    try {
      final response = await http.get(Uri.parse(
          "https://biblioteca1.info/fly2w/getVariable.php?var_nombre=url_logo"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(response.body);
        String remoteValueStr = remoteData['var_valor'].toString();
        String remoteUrl = remoteData['var_descripcion'].toString();
        print("Valor remoto de url_logo: $remoteValueStr, URL: $remoteUrl");
        int? remoteValue = int.tryParse(remoteValueStr);
        int? localValue = int.tryParse(_localLogoVersion);
        if (remoteValue != null && localValue != null && remoteValue > localValue) {
          setState(() {
            _logoLink = remoteUrl;
            _localLogoVersion = remoteValueStr;
          });
          await _writeLocalLogoVariable(remoteValueStr);
          print("Logo actualizado. Nueva versión local: $_localLogoVersion");
        } else {
          if (_logoLink.isEmpty) {
            setState(() {
              _logoLink = remoteUrl;
            });
          }
          print("Logo actualizado o sin cambio (versión local: $_localLogoVersion, remoto: $remoteValueStr)");
        }
      } else {
        print("Error consultando url_logo: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción consultando url_logo: $e");
    }
  }

  /// Lanza la URL del logo usando url_launcher
  Future<void> _launchLogoUrl() async {
    if (_logoLink.isNotEmpty) {
      final Uri url = Uri.parse(_logoLink);
      print("Intentando lanzar URL: $_logoLink");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print("URL lanzada correctamente.");
      } else {
        print("No se pudo abrir la URL: $_logoLink");
      }
    } else {
      print("El valor de _logoLink está vacío.");
    }
  }

  Future<void> loginUser() async {
    final String username = userController.text.trim();
    final String password = passwordController.text.trim();
    final String token = tokenController.text.trim();

    if (username.isEmpty || password.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuario, contraseña y token son obligatorios"),
        ),
      );
      return;
    }

    // Obtener token FCM automáticamente
    final String fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

    // Definir la URL de la API
    final Uri apiUrl = Uri.parse("https://biblioteca1.info/fly2w/registertUser.php");

    try {
      final response = await http.post(apiUrl, body: {
        "p_operacion": "login",
        "username": username,
        "password": password,
        "token": token,
        "fcm_token": fcmToken,
      });

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["status"] == "success") {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          // Guardar los datos completos del usuario
          prefs.setString("userData", json.encode(data["data"]));
          // Almacenar el id del operador por separado
          prefs.setInt("operatorId", int.tryParse(data["data"]["userId"].toString()) ?? 0);
          // Almacenar también el username y token para usarlos en eliminación
          prefs.setString("username", username);
          prefs.setString("userToken", data["data"]["token"].toString());
          // Guardar los datos del usuario en un archivo local
          await _writeLocalUserData(data["data"]);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Error en el login")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión al servidor")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        backgroundColor: blanco,
        title: const Text('Iniciar Sesión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo centrado (clickeable)
            Center(
              child: GestureDetector(
                onTap: _launchLogoUrl,
                child: Image.asset('lib/src/assets/logo.png', height: 80),
              ),
            ),
            const SizedBox(height: 32),
            // Campo para usuario
            TextField(
              controller: userController,
              decoration: InputDecoration(
                labelText: 'Usuario',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campo para contraseña
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            // Campo para el token personalizado
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: azulVibrante,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: loginUser,
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                "Soluciones TEC © 2025",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
