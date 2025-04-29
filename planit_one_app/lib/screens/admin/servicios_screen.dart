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

        final url = Uri.parse('https://web-production-cf32.up.railway.app/api/services/');

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
              _NombreTextFormField(nombreController: _nombreController),
              const SizedBox(height: 16),
              _DescripcionTextFormField(descripcionController: _descripcionController),
              const SizedBox(height: 16),
              _PrecioTextFormField(precioBaseController: _precioBaseController),
              const SizedBox(height: 16),
              _unidadDeMedida(),
              const SizedBox(height: 16),
              _DuracionTextFormField(duracionController: _duracionController),
              const SizedBox(height: 16),  
              _ProveedorTextFormField(proveedorController: _proveedorController),
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

class _ProveedorTextFormField extends StatelessWidget {
  const _ProveedorTextFormField({
    //super.key,
    required TextEditingController proveedorController,
  }) : _proveedorController = proveedorController;

  final TextEditingController _proveedorController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _proveedorController,
      decoration: const InputDecoration(labelText: 'Proveedor'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _DuracionTextFormField extends StatelessWidget {
  const _DuracionTextFormField({
    //super.key,
    required TextEditingController duracionController,
  }) : _duracionController = duracionController;

  final TextEditingController _duracionController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _duracionController,
      decoration: const InputDecoration(labelText: 'Duración estandar (minutos)'),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _PrecioTextFormField extends StatelessWidget {
  const _PrecioTextFormField({
    //super.key,
    required TextEditingController precioBaseController,
  }) : _precioBaseController = precioBaseController;

  final TextEditingController _precioBaseController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _precioBaseController,
      decoration: const InputDecoration(labelText: 'Precio base *'),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _DescripcionTextFormField extends StatelessWidget {
  const _DescripcionTextFormField({
    //super.key,
    required TextEditingController descripcionController,
  }) : _descripcionController = descripcionController;

  final TextEditingController _descripcionController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _descripcionController,
      decoration: const InputDecoration(labelText: 'Descripción'),
      maxLines: 2,
    );
  }
}

class _NombreTextFormField extends StatelessWidget {
  const _NombreTextFormField({
    //super.key,
    required TextEditingController nombreController,
  }) : _nombreController = nombreController;

  final TextEditingController _nombreController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _nombreController,
      decoration: const InputDecoration(labelText: 'Nombre *'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}