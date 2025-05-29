//admin/gest_servicios_screen.dart
import 'dart:developer';
import 'package:planit_one_app/services/api_service.dart';
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

      // final url = Uri.parse('https://web-production-cf32.up.railway.app/services/');
      final url = Uri.parse('${baseUrl}services/');
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
            'id': item['id'],
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


  Future<void> _eliminarService(int serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}services/$serviceId/');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio eliminado correctamente')),
        );
        _cargarServicios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el servicio: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _confirmarEliminar(int serviceId, String nombre) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de eliminar el servicio "$nombre"?'),
                const Text('Esta acción no se puede deshacer.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarService(serviceId);
              },
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
        _botones(servicio),
      ],
    );
  }

  Row _botones(Map<String, dynamic> servicio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _editService(servicio['id']),
          child: const Text('EDITAR'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _confirmarEliminar(servicio['id'], servicio['nombre']),
          child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
