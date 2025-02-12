import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wufastpay/providers/provider.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  

  @override
  _DashboardPageState createState() => _DashboardPageState();
  
}
int _selectedIndex = 0;

class _DashboardPageState extends State<DashboardPage> {
  String? _token;
  double? _saldo;
  String? _nombre;
  String? _correo;
  String? _telefono;
  List<Map<String, dynamic>> _transacciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarToken();
    _cargarTransacciones();
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

Future<void> _obtenerSaldo(String token) async {
  try {
    final userId = await obtenerUserIdDesdeToken(token);
    print("User ID obtenido: $userId"); // Debug

    if (userId != null) {
      final response = await http.get(
        Uri.parse('http://localhost:5225/api/CUENTAS'), // Obtener TODAS las cuentas
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> cuentas = jsonDecode(response.body);
        
        // Filtrar solo las cuentas del usuario actual
        double saldoTotal = 0.0;
        for (var cuenta in cuentas) {
          if (cuenta['user_id'] == userId) {
            saldoTotal += cuenta['saldo'].toDouble();
          }
        }

        setState(() {
          _saldo = saldoTotal;
        });

        print("Saldo total calculado: $_saldo"); // Debug
      } else {
        print('Error al obtener el saldo: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Error al obtener saldo: $e');
  }
}



 Future<void> _cargarToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _token = prefs.getString('auth_token');
  });
  print('Token cargado: $_token'); 

  if (_token != null) {
    _obtenerDatosUsuario(_token!);
    _obtenerSaldo(_token!);
  } else {
    print('No se encontró token');
  }
}



Future<void> _cargarTransacciones() async {
    final String apiUrl = "http://localhost:5225/api/TRANSACCIONES";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _transacciones = data.map((item) => {
            'pais': item['pais'],
            'monto': item['monto'],
            'fecha': _formatearFecha(item['fecha']),
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Error al cargar transacciones");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(String fechaISO) {
    DateTime fecha = DateTime.parse(fechaISO);
    return "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute}";
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/logowu.png', 
              height: 40,
            ),
            const SizedBox(width: 10), 
            const Text('WU FastPay'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Color.fromARGB(255, 0, 0, 0)),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              cerrarSesion();
            },
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
                        _saldo != null ? '\$${_saldo!.toStringAsFixed(2)}' : 'Cargando...',
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
                            fontSize: 10,
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
                  Navigator.pushNamed(context, '/perfil');
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
                    title: Text(transaccion['pais']),  
                    subtitle: Text(transaccion['fecha']),  
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,  
                      children: [
                        Text(
                          '\$${transaccion['monto'].toStringAsFixed(2)}',  
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_downward,  
                          color: Color.fromARGB(255, 255, 2, 2),  
                        ),
                      ],
                    ),
                  ),
                );
              },
            )



          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex, 
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/productos');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/perfil');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Mis productos"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
      ],
      selectedItemColor: Colors.blue, 
      unselectedItemColor: Colors.grey, 
      showUnselectedLabels: true,
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