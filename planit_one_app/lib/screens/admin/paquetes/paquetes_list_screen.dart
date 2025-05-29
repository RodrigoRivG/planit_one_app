// lib/screens/admin/packages/paquetes_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:planit_one_app/screens/admin/paquetes/paquetes_form_screen.dart';
import 'package:planit_one_app/services/api_service.dart';

class PaquetesListScreen extends StatefulWidget {
  const PaquetesListScreen({super.key});

  @override
  State<PaquetesListScreen> createState() => _PaquetesListScreenState();
}

class _PaquetesListScreenState extends State<PaquetesListScreen> {
  List<Map<String, dynamic>> _paquetes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPaquetes();
  }

  Future<void> _cargarPaquetes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      // Cambia la URL a la de tu API
      final url = Uri.parse('${baseUrl}packages/');
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
          _paquetes = data.map((item) => {
            'id': item['id'],
            'nombre': item['name'] ?? '',
            'descripcion': item['description'] ?? '',
            'imagen': item['image'] ?? '',
            'servicios': item['services'] ?? [],
          }).toList();
          _isLoading = false;
        });
      } else {
        print('Error al cargar paquetes: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _crearPaquete() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaquetesFormScreen(),
      ),
    ).then((_) => _cargarPaquetes());
  }

  void _editarPaquete(int paqueteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaquetesFormScreen(paqueteId: paqueteId),
      ),
    ).then((_) => _cargarPaquetes());
  }

  Future<void> _eliminarPaquete(int paqueteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}packages/$paqueteId/');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete eliminado correctamente')),
        );
        _cargarPaquetes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el paquete: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _confirmarEliminar(int paqueteId, String nombre) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de eliminar el paquete "$nombre"?'),
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
                _eliminarPaquete(paqueteId);
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
        title: const Text('Paquetes'),
        actions: [
          IconButton(
            onPressed: _crearPaquete,
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo Paquete',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _paquetes.isEmpty
          ? const Center(child: Text('No hay paquetes disponibles'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _paquetes.length,
              itemBuilder: (context, index) {
                final paquete = _paquetes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _listCard(paquete, index),
                  ),
                );
              },
            ),
    );
  }

  Column _listCard(Map<String, dynamic> paquete, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paquete['imagen'] != null && paquete['imagen'].isNotEmpty)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(paquete['imagen']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paquete['nombre'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(paquete['descripcion'] ?? ''),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (paquete['servicios'] != null && paquete['servicios'].isNotEmpty) ...[
          const Text(
            'Servicios incluidos:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: (paquete['servicios'] as List).map((servicio) {
              return Chip(
                label: Text(servicio['name'] ?? ''),
                backgroundColor: Colors.blue[100],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        _botones(paquete),
      ],
    );
  }

  Row _botones(Map<String, dynamic> paquete) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _editarPaquete(paquete['id']),
          child: const Text('EDITAR'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _confirmarEliminar(paquete['id'], paquete['nombre']),
          child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}