import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _token;
  double _saldo = 1500.0; // Saldo de ejemplo
  String? _nombre;
  String? _correo;
  String? _telefono;
  final List<Map<String, dynamic>> _transacciones = [
    {'tipo': 'Enviado', 'monto': 100.0, 'destinatario': 'Juan Pérez', 'fecha': '2023-10-01'},
    {'tipo': 'Recibido', 'monto': 50.0, 'destinatario': 'Ana Gómez', 'fecha': '2023-10-02'},
    {'tipo': 'Enviado', 'monto': 200.0, 'destinatario': 'Carlos Ruiz', 'fecha': '2023-10-03'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarToken();
  }

Future<int?> obtenerUserIdDesdeToken(String token) async {
  final response = await http.get(
    Uri.parse('http://localhost:5225/api/USUARIOS/GetUserByToken/$token'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print('Error al obtener user_id');
    return null;
  }
}



bool _cargando = true;

Future<void> _obtenerDatosUsuario(String token) async {
  setState(() {
    _cargando = true;
  });

  try {
    final userId = await obtenerUserIdDesdeToken(token);

    if (userId != null) {
      final response = await http.get(
        Uri.parse('http://localhost:5225/api/USUARIOS/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final datosUsuario = jsonDecode(response.body);
        setState(() {
          _nombre = datosUsuario['nombre'];
          _correo = datosUsuario['email'];
          _telefono = datosUsuario['telefono'];
          _cargando = false;
        });
      } else {
        print('Error al obtener los datos del usuario');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    setState(() {
      _cargando = false;
    });
  }
}





  /// Cargar el token almacenado
  Future<void> _cargarToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _token = prefs.getString('auth_token');
  });
  print('Token cargado: $_token'); // Agregar para depuración
  if (_token != null) {
    _obtenerDatosUsuario(_token!);
  } else {
    print('No se encontró token');
  }
}



  /// Cerrar sesión y eliminar el token
  Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // Redirigir al login
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('WU FastPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saldo Actual
         

         Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Columna izquierda: Saldo
                Expanded(
                  flex: 3, // Ajuste para dar más espacio a la columna de saldo
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Actual',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_saldo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Columna derecha: Información del usuario
                Expanded(
                  flex: 2, // Ajuste para que esta columna tenga un tamaño adecuado
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_nombre != null)
                        Text(
                          _nombre!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_correo != null)
                        Text(
                          _correo!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      if (_telefono != null)
                        Text(
                          _telefono!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

         
            const SizedBox(height: 20),

            // Acciones Rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.send, 'Transferir', Colors.blue, () {
                  Navigator.pushNamed(context, '/transferir');
                }),
                _buildActionButton(Icons.account_balance_wallet, 'Recargar', Colors.green, () {
                  Navigator.pushNamed(context, '/recargar');
                }),
                _buildActionButton(Icons.history, 'Historial', Colors.orange, () {
                  Navigator.pushNamed(context, '/historial');
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Historial de Transacciones
            const Text(
              'Últimas Transacciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transacciones.length,
              itemBuilder: (context, index) {
                final transaccion = _transacciones[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      transaccion['tipo'] == 'Enviado' ? Icons.arrow_upward : Icons.arrow_downward,
                      color: transaccion['tipo'] == 'Enviado' ? Colors.red : Colors.green,
                    ),
                    title: Text(transaccion['destinatario']),
                    subtitle: Text(transaccion['fecha']),
                    trailing: Text(
                      '\$${transaccion['monto'].toStringAsFixed(2)}',
                      style: TextStyle(
                        color: transaccion['tipo'] == 'Enviado' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    
  }

  /// Botón de acción rápida
  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}