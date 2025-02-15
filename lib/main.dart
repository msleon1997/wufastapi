import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wufastpay/pages/historialTrans.dart';
import 'package:wufastpay/pages/recargar.dart';
import 'package:wufastpay/pages/transaccion.dart';
import 'package:wufastpay/providers/provider.dart';
import 'pages/dashboard.dart';
import 'pages/login.dart'; 
import 'pages/productos.dart';
import 'pages/register.dart'; 
import 'pages/perfil.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Banca Móvil',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/perfil': (context) => const PerfilPage(),
          '/productos': (context) => const ProductosPage(),
          '/transferir': (context) => TransactionScreen(),
          '/historial': (context) => HistorialPage(),
          '/recargar': (context) => RecargarPage(),


        },
      ),
    );
  }
}