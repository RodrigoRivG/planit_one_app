import 'package:flutter/material.dart';
import 'package:planit_one_app/screens/admin/servicios_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GestionarServiciosScreen extends StatefulWidget {
  const GestionarServiciosScreen({super.key});

  @override
  State<GestionarServiciosScreen> createState() =>
      _GestionarServiciosScreenState();
}

class _GestionarServiciosScreenState extends State<GestionarServiciosScreen> {
  List<Map<String, dynamic>> _servicios = [];

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      // final url = Uri.parse('https://web-production-cf32.up.railway.app/api/services/');
      final url = Uri.parse('http://192.168.100.23:8000/api/services/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _servicios = data.map((item) => {
            'nombre': item['name'] ?? '',
            'descripcion': item['description'] ?? '',
            'precio': '\$${item['base_price'] ?? '0.00'}',
            'unidad': item['unit_measure'] ?? '',
            'duracion': '${item['standard_duration'] ?? '0'} minutos',
            'proveedor': item['provider'] ?? '',
          }).toList();
        });
      } else {
        print('Error al cargar servicios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  void _newService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServiciosScreen()),
    );
  }

  void _editService(int index) {
    // ?
  }

  void _deleteService(int index) {
    setState(() {
      _servicios.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('Servicios'),
        actions: [
          IconButton(
            onPressed: _newService,
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo Servicio',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _servicios.length,
        itemBuilder: (context, index) {
          final servicio = _servicios[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _listCard(servicio, index),
            ),
          );
        },
      ),
    );
  }

  Column _listCard(Map<String, dynamic> servicio, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          servicio['nombre'] ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(servicio['descripcion'] ?? ''),
        const SizedBox(height: 8),
        Text('Precio: ${servicio['precio']}'),
        const SizedBox(height: 8),
        Text('Unidad: ${servicio['unidad']}'),
        const SizedBox(height: 8),
        Text('Duración: ${servicio['duracion']}'),
        const SizedBox(height: 8),
        Text('Proveedor: ${servicio['proveedor']}'),
        const SizedBox(height: 12),
        _botones(index),
      ],
    );
  }

  Row _botones(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _editService(index),
          child: const Text('EDITAR'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _deleteService(index),
          child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
