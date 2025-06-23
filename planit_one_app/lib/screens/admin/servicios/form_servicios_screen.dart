//admin/servicios_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planit_one_app/services/api_service.dart';
import 'dart:convert';

class ServiciosScreen extends StatefulWidget {
  final Map<String, dynamic>? servicio; // Para editar un servicio existente

  const ServiciosScreen({super.key, this.servicio});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioBaseController = TextEditingController();
  final TextEditingController _duracionController = TextEditingController();

  String? _unidadMedidaSeleccionada;
  int? _proveedorSeleccionado;

  List<Map<String, dynamic>> _proveedores = [];
  bool _isLoading = true;
  bool _isEditing = false;

  final List<String> _unidadesDeMedida = [
    'event',
    'hour',
    'person',
    'day',
    'unit',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.servicio != null;
    _cargarProveedores();
    if (_isEditing) {
      _cargarDatosServicio();
    }
  }

  void _cargarDatosServicio() {
    final servicio = widget.servicio!;
    _nombreController.text = servicio['name'] ?? '';
    _descripcionController.text = servicio['description'] ?? '';
    _precioBaseController.text = servicio['base_price']?.toString() ?? '';
    _duracionController.text = servicio['standard_duration']?.toString() ?? '';
    _unidadMedidaSeleccionada = servicio['unit_measure'];
    _proveedorSeleccionado = servicio['provider'];
  }

  Future<void> _cargarProveedores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      // Usar el endpoint 'active' para obtener solo proveedores activos
      final url = Uri.parse('${baseUrl}providers/active/');

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
          _proveedores =
              data
                  .map(
                    (item) => {
                      'id': item['id'],
                      'name':
                          item['commercial_name'] ??
                          '', // Cambiar 'name' por 'commercial_name'
                    },
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        print('Error al cargar proveedores: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar proveedores: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioBaseController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  void _guardarServicio() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token') ?? '';

        final url =
            _isEditing
                ? Uri.parse('${baseUrl}services/${widget.servicio!['id']}/')
                : Uri.parse('${baseUrl}services/');

        final response =
            _isEditing
                ? await http.put(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'name': _nombreController.text.trim(),
                    'description': _descripcionController.text.trim(),
                    'base_price':
                        double.tryParse(_precioBaseController.text.trim()) ??
                        0.0,
                    'unit_measure': _unidadMedidaSeleccionada,
                    'standard_duration':
                        _duracionController.text.trim().isNotEmpty
                            ? int.tryParse(_duracionController.text.trim())
                            : null,
                    'provider': _proveedorSeleccionado,
                  }),
                )
                : await http.post(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'name': _nombreController.text.trim(),
                    'description': _descripcionController.text.trim(),
                    'base_price':
                        double.tryParse(_precioBaseController.text.trim()) ??
                        0.0,
                    'unit_measure': _unidadMedidaSeleccionada,
                    'standard_duration':
                        _duracionController.text.trim().isNotEmpty
                            ? int.tryParse(_duracionController.text.trim())
                            : null,
                    'provider': _proveedorSeleccionado,
                  }),
                );

        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Servicio actualizado exitosamente'
                    : 'Servicio creado exitosamente',
              ),
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // Retorna true para indicar que se guardó
        } else {
          print('Respuesta: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al ${_isEditing ? 'actualizar' : 'crear'} servicio: ${response.statusCode}',
              ),
            ),
          );
        }
      } catch (e) {
        print('Error de conexión: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
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
        title: Text(_isEditing ? 'Editar Servicio' : 'Nuevo Servicio'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _CustomTextFormField(
                        controller: _nombreController,
                        label: 'Nombre *',
                      ),
                      const SizedBox(height: 16),
                      _CustomTextFormField(
                        controller: _descripcionController,
                        label: 'Descripción',
                      ),
                      const SizedBox(height: 16),
                      _CustomTextFormField(
                        controller: _precioBaseController,
                        label: 'Precio base *',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _unidadDeMedida(),
                      const SizedBox(height: 16),
                      _CustomTextFormField(
                        controller: _duracionController,
                        label: 'Duración estándar (minutos)',
                        keyboardType: TextInputType.number,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _proveedorDropdown(),
                      const SizedBox(height: 24),
                      _botones(),
                    ],
                  ),
                ),
              ),
    );
  }

  DropdownButtonFormField<int> _proveedorDropdown() {
    return DropdownButtonFormField<int>(
      value: _proveedorSeleccionado,
      decoration: const InputDecoration(labelText: 'Proveedor *'),
      items:
          _proveedores.map((proveedor) {
            return DropdownMenuItem<int>(
              value: proveedor['id'],
              child: Text(
                proveedor['name'],
              ), // Esto ahora contendrá 'commercial_name'
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _proveedorSeleccionado = value;
        });
      },
      validator:
          (value) => value == null ? 'Debe seleccionar un proveedor' : null,
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
            minimumSize: const Size(50, 40),
          ),
          child: const Text(
            'CANCELAR',
            style: TextStyle(color: Colors.lightBlue),
          ),
        ),
        ElevatedButton(
          onPressed: _guardarServicio,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[400],
            minimumSize: const Size(50, 40),
          ),
          child: Text(
            _isEditing ? 'ACTUALIZAR' : 'GUARDAR',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  DropdownButtonFormField<String> _unidadDeMedida() {
    return DropdownButtonFormField<String>(
      value: _unidadMedidaSeleccionada,
      decoration: const InputDecoration(labelText: 'Unidad de medida *'),
      items:
          _unidadesDeMedida.map((unidad) {
            return DropdownMenuItem<String>(value: unidad, child: Text(unidad));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _unidadMedidaSeleccionada = value;
        });
      },
      validator:
          (value) =>
              value == null ? 'Debe seleccionar una unidad de medida' : null,
    );
  }
}

class _CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool required;

  const _CustomTextFormField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator:
          required
              ? (value) =>
                  value == null || value.isEmpty ? 'Campo obligatorio' : null
              : null,
    );
  }
}
