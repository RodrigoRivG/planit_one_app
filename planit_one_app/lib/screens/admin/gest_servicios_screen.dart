import 'package:flutter/material.dart';
import 'package:planit_one_app/screens/admin/servicios_screen.dart';

class GestionarServiciosScreen extends StatefulWidget {
  const GestionarServiciosScreen({super.key});

  @override
  State<GestionarServiciosScreen> createState() =>
      _GestionarServiciosScreenState();
}

class _GestionarServiciosScreenState extends State<GestionarServiciosScreen> {
  final List<Map<String, String>> _servicios = [
    {
      'nombre': 'Servicio de Catering',
      'descripcion': 'Catering Gourmet para Eventos Corporativos',
      'precio': '\$50.00',
      'unidad': 'Por Persona',
      'duracion': '180 minutos',
      'proveedor': 'Delicias Gourmet Catering',
    },
    {
      'nombre': 'Servicio de Música en Vivo',
      'descripcion': 'Conjunto Acústico para Recepciones',
      'precio': '\$1200.00',
      'unidad': 'Por Evento',
      'duracion': '120 minutos',
      'proveedor': 'Sonidos del Alma',
    },
  ];

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

  Column _listCard(Map<String, String> servicio, int index) {
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
