import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './auth/login_screen.dart';
import 'admin/gest_servicios_screen.dart';

class HomeScreen extends StatelessWidget {
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => logout(context),
          ),
        ],
      ),
      //body: Center(child: Text('¡Bienvenido!')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¡Bienvenido!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GestionarServiciosScreen()),
                );
              },
              child: const Text('Gestionar Servicios'),
            ),
          ],
        ),
      ),
    );
  }
}
