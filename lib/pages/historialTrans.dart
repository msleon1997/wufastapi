import 'package:flutter/material.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}
int _selectedIndex = 0;

class _HistorialPageState extends State<HistorialPage> {
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