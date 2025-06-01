import 'package:flutter/material.dart';
import 'package:planit_one_app/screens/admin/gest_servicios_screen.dart';
import 'package:planit_one_app/screens/admin/locacion_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planit_one_app/screens/admin/paquetes/paquetes_list_screen.dart';
import '../auth/login_screen.dart';
import 'package:planit_one_app/screens/admin/agenda_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // aqui copio lo de Erik
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
        backgroundColor: Colors.blue[400],
        title: const Text('Panel de Administrador'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
            tooltip: 'Cerra sesión',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.blue[400],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Administrador',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                // Gestionar Servicios
                leading: const Icon(Icons.build, color: Colors.white),
                title: const Text(
                  'Gestionar Servicios',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Gestionar Servicios
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionarServiciosScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.white),
                title: const Text(
                  'Gestionar Locaciones',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Gestionar locacion
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocacionScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.inventory, color: Colors.white),
                title: Text(
                  'Getionar Paquetes',
                 style: TextStyle(color: Colors.white),
                 ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaquetesListScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event, color: Colors.white),
                title: const Text('Agenda de Eventos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AgendaScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text('Bienvenido al Dashboard', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
