import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://localhost:5225/api/USUARIOS/register";

Future<void> registrarUsuario(Map<String, dynamic> usuario) async {
  try {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(usuario),
    );

    if (response.statusCode == 201) {
      // Registro exitoso
      print('Usuario registrado exitosamente');
    } else {
      // Manejo de errores
      print('Error en la solicitud: ${response.statusCode}');
      print('Respuesta del servidor: ${response.body}');
      throw Exception('Error al registrar el usuario: ${response.body}');
      
    }
  } catch (e) {
    print('Excepción: $e');
    rethrow;
  }

}
}