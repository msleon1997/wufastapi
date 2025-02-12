/* import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/provider.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedRecipient;
  int? _selectedAccountId; // Cambiado para almacenar el account_id
  String? _selectedCountry;
  List<Map<String, dynamic>> _recipients = [];
  List<Map<String, dynamic>> _accounts = [];
  List<String> _countries = ["Ecuador", "Colombia", "Perú", "Chile", "Argentina"];

  int? _userId;

  @override
  void initState() {
    super.initState();
    _obtenerDatosUsuario();
    _fetchBeneficiaries();
    _fetchAccounts();
  }

  Future<void> _obtenerDatosUsuario() async {
    final String userApiUrl = "http://localhost:5225/api/USUARIOS/GetUserByToken";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

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
      });
    }
  }

  Future<void> _fetchBeneficiaries() async {
    final String apiUrl = "http://localhost:5225/api/BENEFICIARIOS?user_id=${_userId}";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _recipients = data.map((beneficiary) => {
          "nombre": beneficiary["nombre"],
          "numero_cuenta": beneficiary["numero_cuenta"],
          "banco": beneficiary["banco"]
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los beneficiarios')),
      );
    }
  }

  Future<void> _fetchAccounts() async {
    final String apiUrl = "http://localhost:5225/api/CUENTAS?user_id=${_userId}";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _accounts = data.map((account) => {
          "account_id": account["account_id"], // Incluir el account_id
          "numero_cuenta": account["numero_cuenta"],
          "saldo": account["saldo"]
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener las cuentas')),
      );
    }
  }

  Future<void> _savebeneficiary() async {
    if (_nameController.text.isEmpty || _accountNumberController.text.isEmpty || _bankController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    await _obtenerDatosUsuario();
    final String apiUrl = "http://localhost:5225/api/BENEFICIARIOS";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final Map<String, dynamic> data = {
      "user_id": _userId,
      "nombre": _nameController.text,
      "numero_cuenta": _accountNumberController.text,
      "banco": _bankController.text,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      setState(() {
        _recipients.add({
          "nombre": _nameController.text,
          "numero_cuenta": _accountNumberController.text,
          "banco": _bankController.text
        });
        _selectedRecipient = _nameController.text;
      });
      _nameController.clear();
      _accountNumberController.clear();
      _bankController.clear();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el beneficiario')),
      );
    }
  }

  Future<void> _realizarTransaccion() async {
    if (_selectedAccountId == null || _selectedRecipient == null || _amountController.text.isEmpty || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    final String apiUrl = "http://localhost:5225/api/TRANSACCIONES";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final Map<String, dynamic> data = {
      "account_id": _selectedAccountId, // Usar el account_id
      "tipo": "Transaccion",
      "monto": double.parse(_amountController.text),
      "fecha": DateTime.now().toIso8601String(),
      "descripcion": _descriptionController.text,
      "pais": _selectedCountry,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transacción realizada con éxito')),
        
      );
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/dashboard');
    });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la transacción')),
      );
    }
  }

  void _showAddRecipientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Agregar nuevo destinatario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: _accountNumberController,
                decoration: InputDecoration(labelText: "Número de cuenta"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bankController,
                decoration: InputDecoration(labelText: "Banco"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: _savebeneficiary,
              child: Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _selectedAccountId,
              decoration: InputDecoration(labelText: "Cuenta"),
              items: _accounts.map((account) {
                return DropdownMenuItem(
                  value: account["account_id"] as int, // Usar el account_id como valor
                  child: Text("${account["numero_cuenta"]} - Saldo: \$${account["saldo"]}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value; // Almacenar el account_id seleccionado
                });
              },
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRecipient,
                    decoration: InputDecoration(labelText: "Destinatario"),
                    items: _recipients.map((recipient) {
                      return DropdownMenuItem(
                        value: recipient["nombre"] as String?,
                        child: Text(recipient["nombre"]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRecipient = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _showAddRecipientDialog,
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(labelText: "País"),
              items: _countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: "Monto"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Descripción"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _realizarTransaccion,
              child: Text("Realizar Transacción"),
            ),
          ],
        ),
      ),
    );
  }
} */







import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/provider.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _debitTotalController = TextEditingController();
  String? _selectedRecipient;
  int? _selectedAccountId;
  String? _selectedCountry;
  List<Map<String, dynamic>> _recipients = [];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _countries = [
    {"name": "Colombia", "comision": 5, "impuesto": 1},
    {"name": "Peru", "comision": 15, "impuesto": 2},
    {"name": "Chile", "comision": 50, "impuesto": 5},
    {"name": "Argentina", "comision": 100, "impuesto": 10},
    {"name": "Paraguay", "comision": 20, "impuesto": 3},
    {"name": "Uruguay", "comision": 10, "impuesto": 4},
    {"name": "Brasil", "comision": 200, "impuesto": 8},
  ];

  int? _userId;

  @override
  void initState() {
    super.initState();
    _obtenerDatosUsuario();
    _fetchBeneficiaries();
    _fetchAccounts();
    _amountController.addListener(_updateDebitTotal);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateDebitTotal);
    super.dispose();
  }

  void _updateDebitTotal() {
    if (_selectedCountry != null && _amountController.text.isNotEmpty) {
      final selectedCountry = _countries.firstWhere(
            (country) => country["name"] == _selectedCountry,
      );
      final comision = selectedCountry["comision"];
      final impuesto = selectedCountry["impuesto"];
      final monto = double.tryParse(_amountController.text) ?? 0;
      final total = monto + comision + (monto * impuesto / 100);
      _debitTotalController.text = total.toStringAsFixed(2);
    } else {
      _debitTotalController.text = "";
    }
  }

  Future<void> _obtenerDatosUsuario() async {
    final String userApiUrl = "http://localhost:5225/api/USUARIOS/GetUserByToken";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

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
      });
    }
  }

  Future<void> _fetchBeneficiaries() async {
    final String apiUrl = "http://localhost:5225/api/BENEFICIARIOS?user_id=${_userId}";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _recipients = data.map((beneficiary) => {
          "nombre": beneficiary["nombre"],
          "numero_cuenta": beneficiary["numero_cuenta"],
          "banco": beneficiary["banco"]
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener los beneficiarios')),
      );
    }
  }

  Future<void> _fetchAccounts() async {
    final String apiUrl = "http://localhost:5225/api/CUENTAS?user_id=${_userId}";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _accounts = data.map((account) => {
          "account_id": account["account_id"],
          "numero_cuenta": account["numero_cuenta"],
          "saldo": account["saldo"]
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener las cuentas')),
      );
    }
  }

  Future<void> _savebeneficiary() async {
    if (_nameController.text.isEmpty || _accountNumberController.text.isEmpty || _bankController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    await _obtenerDatosUsuario();
    final String apiUrl = "http://localhost:5225/api/BENEFICIARIOS";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final Map<String, dynamic> data = {
      "user_id": _userId,
      "nombre": _nameController.text,
      "numero_cuenta": _accountNumberController.text,
      "banco": _bankController.text,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      setState(() {
        _recipients.add({
          "nombre": _nameController.text,
          "numero_cuenta": _accountNumberController.text,
          "banco": _bankController.text
        });
        _selectedRecipient = _nameController.text;
      });
      _nameController.clear();
      _accountNumberController.clear();
      _bankController.clear();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el beneficiario')),
      );
    }
  }

  Future<void> _realizarTransaccion() async {
    if (_selectedAccountId == null || _selectedRecipient == null || _amountController.text.isEmpty || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    final String apiUrl = "http://localhost:5225/api/TRANSACCIONES";
    final String? token = Provider.of<AppProvider>(context, listen: false).token;

    final Map<String, dynamic> data = {
      "account_id": _selectedAccountId,
      "tipo": "Transaccion",
      "monto": double.parse(_amountController.text),
      "fecha": DateTime.now().toIso8601String(),
      "descripcion": _descriptionController.text,
      "pais": _selectedCountry,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transacción realizada con éxito')),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la transacción')),
      );
    }
  }

  void _showAddRecipientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Agregar nuevo destinatario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: _accountNumberController,
                decoration: InputDecoration(labelText: "Número de cuenta"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bankController,
                decoration: InputDecoration(labelText: "Banco"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: _savebeneficiary,
              child: Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transacciones", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: "Cuenta",
                        border: OutlineInputBorder(),
                      ),
                      items: _accounts.map((account) {
                        return DropdownMenuItem(
                          value: account["account_id"] as int,
                          child: Text("${account["numero_cuenta"]} - Saldo: \$${account["saldo"]}"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRecipient,
                            decoration: InputDecoration(
                              labelText: "Destinatario",
                              border: OutlineInputBorder(),
                            ),
                            items: _recipients.map((recipient) {
                              return DropdownMenuItem(
                                value: recipient["nombre"] as String?,
                                child: Text(recipient["nombre"]),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRecipient = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.blue),
                          onPressed: _showAddRecipientDialog,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: InputDecoration(
                        labelText: "País",
                        border: OutlineInputBorder(),
                      ),
                      items: _countries.map((country) {
                        return DropdownMenuItem(
                          value: country["name"] as String?,
                          child: Text("${country["name"]} (Comisión: \$${country["comision"]}, Impuesto: ${country["impuesto"]}%)"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                          _updateDebitTotal();
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: "Monto",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Descripción",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _debitTotalController,
                      decoration: InputDecoration(
                        labelText: "Débito Total",
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _realizarTransaccion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                "Realizar Transacción",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}