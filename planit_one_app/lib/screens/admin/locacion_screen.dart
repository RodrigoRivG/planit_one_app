import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocacionScreen extends StatefulWidget {
  const LocacionScreen({super.key});

  @override
  State<LocacionScreen> createState() => _LocacionScreenState();
}

class _LocacionScreenState extends State<LocacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameLocationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _rentalPriceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _parkingSpaceController = TextEditingController();
  final TextEditingController _extraHourCostController =
      TextEditingController();
  final TextEditingController _providerController = TextEditingController();

  String? _locationTypeSelecte;
  String? _priceUnitSelected;
  String? _environmentTypeSelected;

  final List<String> _locationTypes = [
    'Salón',
    'Jardín',
    'Playa',
    'Auditorio',
    'Terraza',
    'Otro',
  ];
  final List<String> _priceUnits = ['Por Evento', 'Por Hora', 'Por Día'];
  final List<String> _environmentTypes = ['Cerrado', 'Abierto', 'Semiabierto'];

  @override
  void dispose() {
    _nameLocationController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _rentalPriceController.dispose();
    _areaController.dispose();
    _parkingSpaceController.dispose();
    _extraHourCostController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  // void _setLocation() {
  //   if (_formKey.currentState!.validate()) {
  //     // quiero la API, servidor a la nube gaaaaaa

  //   }
  // }

  void _setLocation() async {
  if (_formKey.currentState!.validate()) {
    final Map<String, String> _locationTypeMap = {
      'Salón': 'salon',
      'Jardín': 'jardin',
      'Playa': 'playa',
      'Auditorio': 'auditorio',
      'Terraza': 'terraza',
      'Otro': 'otro',
    };

    final Map<String, String> _priceUnitMap = {
      'Por Evento': 'event',
      'Por Hora': 'hour',
      'Por Día': 'day',
    };

    final Map<String, String> _environmentTypeMap = {
      'Cerrado': 'cerrado',
      'Abierto': 'abierto',
      'Semiabierto': 'semiabierto',
    };

    final Map<String, dynamic> data = {
      'name': _nameLocationController.text,
      'description': _descriptionController.text,
      'address': _addressController.text,
      'location_type': _locationTypeMap[_locationTypeSelecte] ?? '',
      'environment_type': _environmentTypeMap[_environmentTypeSelected] ?? '',
      'capacity': int.tryParse(_capacityController.text) ?? 0,
      'area_sqm': int.tryParse(_areaController.text) ?? 0,
      'parking_spaces': int.tryParse(_parkingSpaceController.text) ?? 0,
      'rental_price': double.tryParse(_rentalPriceController.text) ?? 0,
      'price_unit': _priceUnitMap[_priceUnitSelected] ?? '',
      'extra_hour_cost': double.tryParse(_extraHourCostController.text) ?? 0,
      'provider': _providerController.text,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final response = await http.post(
        Uri.parse('${baseUrl}locations/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Reemplaza con tu JWT si aplica
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Locación guardada con éxito')),
        );
        Navigator.pop(context); // o navega a otra pantalla
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('Gestionar Locación')
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _CustomTextFormField(controller: _nameLocationController, label: 'Locación'),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _descriptionController, label: 'Descripción'),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _addressController, label: 'Dirección'),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _capacityController, label: 'Capacidad de personas', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _locationType(),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _rentalPriceController, label: 'Precio del alquiler', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _priceUnit(),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _areaController, label: 'Área (m2)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _parkingSpaceController, label: 'Estacionamiento (vehículos)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _environmentType(),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _extraHourCostController, label: 'Costo por horas extras', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _CustomTextFormField(controller: _providerController, label: 'Proveedor asociado'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _setLocation,
                child: const Text('GUARDAR LOCACIÓN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DropdownButtonFormField<String> _environmentType() {
    return DropdownButtonFormField(
      value: _environmentTypeSelected,
      decoration: const InputDecoration(labelText: 'Tipo de ambiente'),
      items:
          _environmentTypes.map((environment) {
            return DropdownMenuItem(
              value: environment,
              child: Text(environment),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _environmentTypeSelected = value;
        });
      },
    );
  }

  DropdownButtonFormField<String> _priceUnit() {
    return DropdownButtonFormField(
      value: _priceUnitSelected,
      decoration: const InputDecoration(
        labelText: 'Unidad de medida del precio',
      ),
      items:
          _priceUnits.map((price) {
            return DropdownMenuItem(value: price, child: Text(price));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _priceUnitSelected = value;
        });
      },
    );
  }

  DropdownButtonFormField<String> _locationType() {
    return DropdownButtonFormField<String>(
      value: _locationTypeSelecte,
      decoration: const InputDecoration(labelText: 'Tipo de locación'),
      items:
          _locationTypes.map((location) {
            return DropdownMenuItem(value: location, child: Text(location));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _locationTypeSelecte = value;
        });
      },
    );
  }
}

//---------------------------------------------------
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