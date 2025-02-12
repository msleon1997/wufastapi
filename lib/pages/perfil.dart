import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPagelState();
}

int _selectedIndex = 0;

class _PerfilPagelState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  String? _token;
  int? _userId;
  String _numeroCuenta = "";
  String _tipoCuenta = "ahorros";
  double _saldo = 0;
  String _fechaCreacion = "";
  bool _isLoading = false;
  bool _isTokenValid = false;
  bool _cargando = true;

  List<Map<String, dynamic>> _cuentas = []; // Lista para visualizar las cuentas

  final String apiUrl = "http://localhost:5225/api/CUENTAS";
  final String userApiUrl = "http://localhost:5225/api/USUARIOS/GetUserByToken";

  @override
  void initState() {
    super.initState();
    _verificarToken();
  }

  Future<void> _verificarToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token != null) {
      setState(() {
        _token = token;
      });
      await _obtenerDatosUsuario(token);
    } else {
      print('No se encontró token');
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _obtenerDatosUsuario(String token) async {
    final response = await http.get(
      Uri.parse("$userApiUrl/$token"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _userId = jsonDecode(response.body);
        _isTokenValid = true;
        _cargando = false;
        _cargarCuentas();
      });
    } else {
      print('Error al obtener user_id');
      setState(() {
        _isTokenValid = false;
        _cargando = false;
      });
    }
  }

  void _generarDatosIniciales() {
    final random = Random();
    setState(() {
      _numeroCuenta = List.generate(10, (index) => random.nextInt(10)).join();
      _fechaCreacion = DateTime.now().toIso8601String();
    });
  }

  Future<void> _cargarCuentas() async {
    if (_userId == null) return;

    final response = await http.get(
      Uri.parse("$apiUrl?user_id=$_userId"),
      headers: {"Authorization": "Bearer $_token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        _cuentas = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print("Error al cargar cuentas");
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> data = {
      "user_id": _userId,
      "numero_cuenta": _numeroCuenta,
      "tipo_cuenta": _tipoCuenta,
      "saldo": _saldo,
      "fecha_creacion": _fechaCreacion,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode(data),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      _cargarCuentas();
      Navigator.pop(context); // Cierra el modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cuenta guardada exitosamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar la cuenta")),
      );
    }
  }

  
    Future<void> _editarCuenta(Map<String, dynamic> cuenta) async {
      String numeroCuenta = cuenta["numero_cuenta"];
      String tipoCuenta = cuenta["tipo_cuenta"];
      double saldo = cuenta["saldo"];
      int accountId = cuenta["account_id"];
      String fechaCreacion = cuenta["fecha_creacion"];

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Editar Cuenta"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: numeroCuenta,
                    decoration: const InputDecoration(labelText: "Número de Cuenta"),
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: tipoCuenta,
                    decoration: const InputDecoration(labelText: "Tipo de Cuenta"),
                    items: const [
                      DropdownMenuItem(value: "ahorros", child: Text("Ahorros")),
                      DropdownMenuItem(value: "corriente", child: Text("Corriente")),
                    ],
                    onChanged: (value) {
                      tipoCuenta = value!;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: saldo.toString(),
                    decoration: const InputDecoration(labelText: "Saldo"),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Ingrese el saldo";
                      if (double.tryParse(value) == null) return "Saldo no válido";
                      return null;
                    },
                    onSaved: (value) => saldo = double.parse(value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final response = await http.put(
                      Uri.parse("$apiUrl/$accountId"),  // Usamos `accountId` en la URL
                      headers: {
                        "Content-Type": "application/json",
                        "Authorization": "Bearer $_token",
                      },
                      body: jsonEncode({
                        "account_id": accountId,  
                        "user_id": _userId,  
                        "numero_cuenta": numeroCuenta,
                        "tipo_cuenta": tipoCuenta,
                        "saldo": saldo,
                        "fecha_creacion": fechaCreacion,  
                      }),
                    );

                    if (response.statusCode == 204) {
                      _cargarCuentas();  // Recarga las cuentas
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cuenta actualizada")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al actualizar")),
                      );
                    }
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );
    }




 Future<void> _eliminarCuenta(int accountId) async {
  final response = await http.delete(
    Uri.parse("$apiUrl/$accountId"),
    headers: {
      "Authorization": "Bearer $_token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 204) {
    _cargarCuentas();  
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cuenta eliminada exitosamente")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error al eliminar la cuenta")),
    );
  }
}


  void _mostrarModalCreacion() {
    _generarDatosIniciales();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Crear Cuenta"),
          content: _buildFormulario(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: _saveAccount,
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: _numeroCuenta,
            decoration: const InputDecoration(labelText: "Número de Cuenta"),
            readOnly: true,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _tipoCuenta,
            decoration: const InputDecoration(labelText: "Tipo de Cuenta"),
            items: const [
              DropdownMenuItem(value: "ahorros", child: Text("Ahorros")),
              DropdownMenuItem(value: "corriente", child: Text("Corriente")),
            ],
            onChanged: (value) {
              setState(() {
                _tipoCuenta = value!;
              });
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: _saldo.toString(),
            decoration: const InputDecoration(labelText: "Saldo"),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return "Ingrese el saldo";
              if (double.tryParse(value) == null) return "Saldo no válido";
              return null;
            },
            onSaved: (value) => _saldo = double.parse(value!),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCuentas() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _cuentas.length,
      itemBuilder: (context, index) {
        final cuenta = _cuentas[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text("Cuenta: ${cuenta['numero_cuenta']}"),
            subtitle: Text("Tipo: ${cuenta['tipo_cuenta']} - Saldo: \$${cuenta['saldo']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarCuenta(cuenta)
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarCuenta(cuenta['account_id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WU FastPay')),
      body: Column(
        children: [
          Expanded(child: _buildListaCuentas()),
          ElevatedButton(
            onPressed: _mostrarModalCreacion,
            child: const Text("Crear Nueva Cuenta"),
          ),
        ],
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
}
