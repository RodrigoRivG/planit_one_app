// lib/screens/admin/packages/paquetes_form_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:planit_one_app/services/api_service.dart';

class PaquetesFormScreen extends StatefulWidget {
  final int? paqueteId;
  
  const PaquetesFormScreen({super.key, this.paqueteId});

  @override
  State<PaquetesFormScreen> createState() => _PaquetesFormScreenState();
}

class _PaquetesFormScreenState extends State<PaquetesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  List<Map<String, dynamic>> _serviciosDisponibles = [];
  List<int> _serviciosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.paqueteId != null;
    _cargarServicios();
    if (_isEditing) {
      _cargarDatosPaquete();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  Future<void> _cargarServicios() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

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
          _serviciosDisponibles = data.map((item) => {
            'id': item['id'],
            'nombre': item['name'] ?? '',
          }).toList();
          
          if (!_isEditing) {
            _isLoading = false;
          }
        });
      } else {
        print('Error al cargar servicios: ${response.statusCode}');
        if (!_isEditing) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error de conexión al cargar servicios: $e');
      if (!_isEditing) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cargarDatosPaquete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}packages/${widget.paqueteId}/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _nombreController.text = data['name'] ?? '';
          _descripcionController.text = data['description'] ?? '';
          _imagenController.text = data['image'] ?? '';
          
          // Obtener IDs de servicios seleccionados
          _serviciosSeleccionados = (data['services'] as List?)
              ?.map<int>((servicio) => servicio['id'] as int)
              .toList() ?? [];
          
          _isLoading = false;
        });
      } else {
        print('Error al cargar datos del paquete: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error de conexión al cargar paquete: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarPaquete() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token') ?? '';
        
        final Map<String, dynamic> body = {
          'name': _nombreController.text.trim(),
          'description': _descripcionController.text.trim(),
          'image': _imagenController.text.trim(),
          'service_ids': _serviciosSeleccionados,
        };

        final Uri url;
        final http.Response response;
        
        if (_isEditing) {
          // Actualizar paquete existente
          url = Uri.parse('${baseUrl}packages/${widget.paqueteId}/');
          response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          );
        } else {
          // Crear nuevo paquete
          url = Uri.parse('${baseUrl}packages/');
          response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          );
        }

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Paquete actualizado exitosamente' : 'Paquete creado exitosamente')),
          );
          Navigator.pop(context); // Volver a la pantalla anterior
        } else {
          print('Error al ${_isEditing ? 'actualizar' : 'crear'} paquete: ${response.statusCode}');
          print('Respuesta: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al ${_isEditing ? 'actualizar' : 'crear'} paquete: ${response.statusCode}')),
          );
        }
        
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Error de conexión: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }
  }

  void _toggleServicio(int servicioId) {
    setState(() {
      if (_serviciosSeleccionados.contains(servicioId)) {
        _serviciosSeleccionados.remove(servicioId);
      } else {
        _serviciosSeleccionados.add(servicioId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: Text(_isEditing ? 'Editar Paquete' : 'Nuevo Paquete'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomTextFormField(controller: _nombreController, label: 'Nombre *'),
                    const SizedBox(height: 16),
                    _CustomTextFormField(
                      controller: _descripcionController, 
                      label: 'Descripción *',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _CustomTextFormField(
                      controller: _imagenController, 
                      label: 'URL de Imagen',
                      keyboardType: TextInputType.url,
                      required: false,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Servicios incluidos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _listaServicios(),
                    const SizedBox(height: 24),
                    _botones(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _listaServicios() {
    if (_serviciosDisponibles.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay servicios disponibles'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _serviciosDisponibles.length,
      itemBuilder: (context, index) {
        final servicio = _serviciosDisponibles[index];
        final bool isSelected = _serviciosSeleccionados.contains(servicio['id']);
        
        return CheckboxListTile(
          title: Text(servicio['nombre']),
          value: isSelected,
          onChanged: (_) => _toggleServicio(servicio['id']),
          activeColor: Colors.blue,
        );
      },
    );
  }

  Row _botones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context), 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size(120, 40),
          ),
          child: const Text(
            'CANCELAR',
            style: TextStyle(
              color: Colors.lightBlue,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _guardarPaquete, 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[400],
            minimumSize: const Size(120, 40),
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
}

class _CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int maxLines;
  final bool required;

  const _CustomTextFormField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: required ? (value) => value!.isEmpty ? 'Campo obligatorio' : null : null,
    );
  }
}