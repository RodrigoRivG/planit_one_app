import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioBaseController = TextEditingController();
  final TextEditingController _duracionController = TextEditingController();
  final TextEditingController _proveedorController = TextEditingController();

  String? _unidadMedidaSeleccionada;

  final List<String> _unidadesDeMedida = ['event', 'hour', 'person', 'day', 'unit']; 

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioBaseController.dispose();
    _duracionController.dispose();
    _proveedorController.dispose();
    super.dispose();
  }

  void _guardarServicio() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token') ?? '';
        // final url = Uri.parse('https://web-production-cf32.up.railway.app/api/services/');
        final url = Uri.parse('http://192.168.100.23:8000/api/services/');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': _nombreController.text.trim(),
            'description': _descripcionController.text.trim(),
            'base_price': double.tryParse(_precioBaseController.text.trim()) ?? 0.0,
            'unit_measure': _unidadMedidaSeleccionada ?? 'Por Evento', // Asegúrate de manejar unidad seleccionada
            'standard_duration': int.tryParse(_duracionController.text.trim()) ?? 0,
            'provider': _proveedorController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          // Éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servicio creado exitosamente')),
          );
          Navigator.pop(context); // Volver a la pantalla anterior
        } else {
          //print('Error al crear servicio: ${response.statusCode}');
          print('Respuesta: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear servicio: ${response.statusCode}')),
          );
        }
        
      } catch (e) {
        print('Error de conexión: $e');
      }
    }
  }

  void _cancelar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('Nuevo Servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _CustomTextFormField(controller: _nombreController, label: 'Nombre *'),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _descripcionController, label: 'Descripción'),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _precioBaseController, label: 'Precio base *', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _unidadDeMedida(),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _duracionController, label: 'Duración estandar (minutos)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),  
              _CustomTextFormField(controller: _proveedorController, label: 'Proveedor'),
              const SizedBox(height: 24),
              _botones(),
            ],
          ),
        ),
      ),
    );
  }

  Row _botones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _cancelar, 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: Size(50, 40),
          ),
          child: const Text(
            'CANCELAR',
            style: TextStyle(
              color: Colors.lightBlue,
            ),
          )
        ),
        ElevatedButton(
          onPressed: _guardarServicio, 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[400],
            minimumSize: Size(50, 40)
          ),
          child: const Text(
            'GUARDAR',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  DropdownButtonFormField<String> _unidadDeMedida() {
    return DropdownButtonFormField<String>(
      value: _unidadMedidaSeleccionada,
      decoration: const InputDecoration(labelText: 'Unidad de medida'),
      items: _unidadesDeMedida.map((unidad) {
        return DropdownMenuItem<String>(
          value: unidad,
          child: Text(unidad),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _unidadMedidaSeleccionada = value;
        });
      },
    );
  }
}

//---------------------------------------------------------
class _CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _CustomTextFormField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}