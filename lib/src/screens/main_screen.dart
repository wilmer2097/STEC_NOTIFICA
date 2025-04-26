import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../main.dart'; // Para los colores y estilos
import '../../src/providers/push_notifications_provider.dart';
import 'webview_page.dart';
import 'login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<NotificationItem> _notifications = [];
  int _notificacionesBD = 0;

  // Variables globales para el logo
  String _operatorName = "";
  String _logoLink = "";
  String _localLogoVersion = "0"; // Guardado en 'logo_variable.json'
  String _appVersion = "";
  
  // Nuevas variables globales (de la tabla Variables)
  String _urlRedirect = "";
  final String _localUrlRedirectVersion = "0"; // Se guardará en 'url_redirect_variable.json'
  String _urlCompartir = "";
  final String _localUrlCompartirVersion = "0"; // Se guardará en 'url_compartir_variable.json'

  @override
  void initState() {
    _loadAppVersion();
    _loadOperatorName();
    super.initState();
    _loadNotificationsFromPrefs();
    _fetchNotificacionesDesdeBD();

    pushNotificationsProvider.onForegroundNotificationReceived =
        (NotificationItem newItem) async {
      setState(() {
        _notifications.add(newItem);
      });
      await _saveNotificationsToPrefs();
      await _fetchNotificacionesDesdeBD();
    };

    // Actualizar variables globales
    _checkAndUpdateUrlRedirect();
    _checkAndUpdateUrlCompartir();

    _loadLocalLogoVariable().then((localVer) {
      _localLogoVersion = localVer ?? "0";
      _checkAndUpdateLogo();
    });
  }

  Future<void> _loadOperatorName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _operatorName = prefs.getString("username") ?? "";
    });
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }
// ----------------------------------------------------------------
// MÉTODO ACTUALIZADO: usa la URL correcta (sin "/fly2w/") y muestra SnackBar en caso de error
Future<void> _fetchNotificacionesDesdeBD() async {
  final prefs      = await SharedPreferences.getInstance();
  final operadorId = prefs.getInt("operatorId") ?? 0;
  if (operadorId == 0) return;

  final Uri apiUrl = Uri.parse(
    "https://fly2w.biblioteca1.info/getNotificacionesOperador.php"
  );

  try {
    final response = await http.post(
      apiUrl,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"operador_id": operadorId}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        setState(() {
          _notificacionesBD = data["notificaciones"];
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al consultar notificaciones: ${response.statusCode}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excepción al traer notificaciones: $e")),
    );
  }
}

// ----------------------------------------------------------------

  // Lógica para el logo (variable global "url_logo")
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

  Future<void> _checkAndUpdateLogo() async {
    try {
      final response = await http.get(Uri.parse(
          "https://fly2w.biblioteca1.info/getVariable.php?var_nombre=url_logo"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(response.body);
        String remoteValueStr = remoteData['var_valor'].toString();
        String remoteUrl = remoteData['var_descripcion'].toString();
        print("Valor remoto de url_logo: $remoteValueStr, URL: $remoteUrl");
        int? remoteValue = int.tryParse(remoteValueStr);
        int? localValue = int.tryParse(_localLogoVersion);
        if (remoteValue != null &&
            localValue != null &&
            remoteValue > localValue) {
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
          print("Logo sin cambio (local: $_localLogoVersion, remoto: $remoteValueStr)");
        }
      } else {
        print("Error consultando url_logo: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción consultando url_logo: $e");
    }
  }

  Future<void> _launchLogoUrl() async {
    if (_logoLink.isNotEmpty) {
      final Uri url = Uri.parse(_logoLink);
      print("Intentando lanzar URL (logo): $_logoLink");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print("Logo: URL lanzada correctamente.");
      } else {
        print("Logo: No se pudo abrir la URL: $_logoLink");
      }
    } else {
      print("El valor de _logoLink está vacío.");
    }
  }

  // --------------------------
  // Lógica para la variable global "url_redirect" (para el botón Revisar)
  Future<String?> _loadLocalUrlRedirectVariable() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/url_redirect_variable.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return data["url_redirect_version"]?.toString();
      }
    } catch (e) {
      print("Error leyendo variable local de url_redirect: $e");
    }
    return null;
  }

  Future<void> _writeLocalUrlRedirectVariable(String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/url_redirect_variable.json');
      Map<String, dynamic> data = {"url_redirect_version": value};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error escribiendo variable local de url_redirect: $e");
    }
  }

  Future<void> _checkAndUpdateUrlRedirect() async {
    try {
      final response = await http.get(Uri.parse(
          "https://fly2w.biblioteca1.info/getVariable.php?var_nombre=url_redirect"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(response.body);
        String remoteValueStr = remoteData['var_valor'].toString();
        String remoteUrl = remoteData['var_descripcion'].toString();
        print("Valor remoto de url_redirect: $remoteValueStr, URL: $remoteUrl");
        int? remoteValue = int.tryParse(remoteValueStr);
        int? localValue = int.tryParse((await _loadLocalUrlRedirectVariable()) ?? "0");
        if (remoteValue != null && localValue != null && remoteValue > localValue) {
          setState(() {
            _urlRedirect = remoteUrl;
          });
          await _writeLocalUrlRedirectVariable(remoteValueStr);
          print("url_redirect actualizado. Nueva versión local: $remoteValueStr");
        } else {
          if (_urlRedirect.isEmpty) {
            setState(() {
              _urlRedirect = remoteUrl;
            });
          }
          print("url_redirect sin cambio (local: $localValue, remoto: $remoteValueStr)");
        }
      } else {
        print("Error consultando url_redirect: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción consultando url_redirect: $e");
    }
  }

  // --------------------------
  // Lógica para la variable global "url_compartir" (para el botón Compartir)
  Future<String?> _loadLocalUrlCompartirVariable() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/url_compartir_variable.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return data["url_compartir_version"]?.toString();
      }
    } catch (e) {
      print("Error leyendo variable local de url_compartir: $e");
    }
    return null;
  }

  Future<void> _writeLocalUrlCompartirVariable(String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/url_compartir_variable.json');
      Map<String, dynamic> data = {"url_compartir_version": value};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error escribiendo variable local de url_compartir: $e");
    }
  }

  Future<void> _checkAndUpdateUrlCompartir() async {
    try {
      final response = await http.get(Uri.parse(
          "https://fly2w.biblioteca1.info/getVariable.php?var_nombre=url_compartir"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(response.body);
        String remoteValueStr = remoteData['var_valor'].toString();
        String remoteUrl = remoteData['var_descripcion'].toString();
        print("Valor remoto de url_compartir: $remoteValueStr, URL: $remoteUrl");
        int? remoteValue = int.tryParse(remoteValueStr);
        int? localValue = int.tryParse((await _loadLocalUrlCompartirVariable()) ?? "0");
        if (remoteValue != null && localValue != null && remoteValue > localValue) {
          setState(() {
            _urlCompartir = remoteUrl;
          });
          await _writeLocalUrlCompartirVariable(remoteValueStr);
          print("url_compartir actualizado. Nueva versión local: $remoteValueStr");
        } else {
          if (_urlCompartir.isEmpty) {
            setState(() {
              _urlCompartir = remoteUrl;
            });
          }
          print("url_compartir sin cambio (local: $localValue, remoto: $remoteValueStr)");
        }
      } else {
        print("Error consultando url_compartir: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción consultando url_compartir: $e");
    }
  }

  // --------------------------
  // Lógica de notificaciones y persistencia en SharedPreferences
  Future<void> _loadNotificationsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('notifications_list');
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        final List<NotificationItem> tempList =
            decoded.map((item) => NotificationItem.fromMap(item)).toList();
        setState(() {
          _notifications.clear();
          _notifications.addAll(tempList);
        });
      }
    } catch (e) {
      debugPrint('Error al decodificar las notificaciones: $e');
    }
  }

  Future<void> _saveNotificationsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> listMap =
        _notifications.map((item) => item.toMap()).toList();
    final jsonString = json.encode(listMap);
    await prefs.setString('notifications_list', jsonString);
  }

  Future<void> _clearNotifications() async {
    setState(() {
      _notifications.clear();
    });
    await _saveNotificationsToPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final int count = _notifications.length;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Espaciado superior y logotipo centrado (clickeable)
            Center(
              child: GestureDetector(
                onTap: _launchLogoUrl,
                child: Image.asset('lib/src/assets/logo.png', height: 120),
              ),
            ),
            const SizedBox(height: 48),
            // Usamos el contador desde la BD
            Text(
              'Tienes $_notificacionesBD pendientes',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Botón "Revisar" (usa la variable global url_redirect y añade el JWT)
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userToken = prefs.getString("userToken") ?? "";

                if (userToken.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No se encontró el token de usuario.")),
                  );
                  return;
                }

                final Uri jwtUrl = Uri.parse("https://fly2w.biblioteca1.info/crearJwt.php");
                try {
                  final resp = await http.post(
                    jwtUrl,
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({"token_usuario": userToken}),
                  );

                  if (resp.statusCode == 200) {
                    final Map<String, dynamic> data = json.decode(resp.body);
                    if (data["status"] == "success") {
                      final newJwt = data["token"];
                      final String base = _urlRedirect.isNotEmpty
                          ? _urlRedirect
                          : "https://fly2w.biblioteca1.info/detalle.php";
                      final String redirectUrl = "$base?token=$newJwt";

                      // Abrir WebView y, al volver, refrescar notificaciones
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WebViewPage(url: redirectUrl)),
                      );

                      // Marcar locales y BD
                      await _clearNotifications();
                      await _fetchNotificacionesDesdeBD();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(data["message"] ?? "Error al generar el token")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error de conexión (${resp.statusCode})")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Excepción: $e")),
                  );
                }
              },
              child: const Text(
                'Revisar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Botón "Mi gestión"
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
              onPressed: () async {
                final Uri url = Uri.parse('flyw365://open/');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: No se pudo abrir la otra app: $e")),
                  );
                }
              },
              child: const Text(
                'Mi gestión',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Botón "Compartir" (usa la variable global url_compartir)
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
              onPressed: () async {
                final String shareUrl = _urlCompartir.isNotEmpty
                    ? _urlCompartir
                    : "https://solucionestecperu.com/"; // Fallback
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WebViewPage(url: shareUrl)),
                );
                await _clearNotifications();
              },
              child: const Text(
                'Compartir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Botón "Eliminar cuenta"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Mostrar diálogo que solicita confirmar la eliminación y pedir la contraseña
                final TextEditingController passConfirmController = TextEditingController();
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Eliminar cuenta"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "¿Está seguro que desea eliminar su cuenta? Ingrese su contraseña para confirmar:",
                        ),
                        TextField(
                          controller: passConfirmController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: "Contraseña"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, ""),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, passConfirmController.text),
                        child: const Text("Eliminar"),
                      ),
                    ],
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  // Obtener el token almacenado (único para el operador) desde SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString("userToken") ?? "";

                  // Llamar a la API para eliminar la cuenta
                  final Uri apiUrl = Uri.parse("https://fly2w.biblioteca1.info/registertUser.php");
                  try {
                    final response = await http.post(apiUrl, body: {
                      "p_operacion": "delete_user",
                      "password": result,
                      "token": token,
                    });
                    final Map<String, dynamic> data = json.decode(response.body);
                    if (data["status"] == "success") {
                      // Cuenta eliminada: limpiar preferencias y redirigir al login
                      await prefs.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(data["message"] ?? "Error al eliminar la cuenta")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
              child: const Text(
                'Eliminar cuenta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: fondoFormulario,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Soluciones TEC © 2025 - v$_appVersion",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              _operatorName,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
