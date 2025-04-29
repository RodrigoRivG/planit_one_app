import 'package:flutter/material.dart';

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

  void _setLocation() {
    if (_formKey.currentState!.validate()) {
      // quiero la API, servidor a la nube aaaaaa
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
              _NameLocation(nameLocationController: _nameLocationController),
              const SizedBox(height: 16),
              _Description(descriptionController: _descriptionController),
              const SizedBox(height: 16),
              _Address(addressController: _addressController),
              const SizedBox(height: 16),
              _Capacity(capacityController: _capacityController),
              const SizedBox(height: 16),
              _locationType(),
              const SizedBox(height: 16),
              _RentalPrice(rentalPriceController: _rentalPriceController),
              const SizedBox(height: 16),
              _priceUnit(),
              const SizedBox(height: 16),
              _Area(areaController: _areaController),
              const SizedBox(height: 16),
              _ParkingSpace(parkingSpaceController: _parkingSpaceController),
              const SizedBox(height: 16),
              _environmentType(),
              const SizedBox(height: 16),
              _ExtraHourCost(extraHourCostController: _extraHourCostController),
              const SizedBox(height: 16),
              _Provider(providerController: _providerController),
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

class _Provider extends StatelessWidget {
  const _Provider({
    //super.key,
    required TextEditingController providerController,
  }) : _providerController = providerController;

  final TextEditingController _providerController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _providerController,
      decoration: const InputDecoration(labelText: 'Proveedor asociado'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _ExtraHourCost extends StatelessWidget {
  const _ExtraHourCost({
    //super.key,
    required TextEditingController extraHourCostController,
  }) : _extraHourCostController = extraHourCostController;

  final TextEditingController _extraHourCostController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _extraHourCostController,
      decoration: const InputDecoration(labelText: 'Costo por horas extras'),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _ParkingSpace extends StatelessWidget {
  const _ParkingSpace({
    //super.key,
    required TextEditingController parkingSpaceController,
  }) : _parkingSpaceController = parkingSpaceController;

  final TextEditingController _parkingSpaceController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _parkingSpaceController,
      decoration: const InputDecoration(
        labelText: 'Estacionamiento (vehículos)',
      ),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _Area extends StatelessWidget {
  const _Area({
    //super.key, 
    required TextEditingController areaController
  }) : _areaController = areaController;

  final TextEditingController _areaController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _areaController,
      decoration: const InputDecoration(labelText: 'Área (m2)'),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _RentalPrice extends StatelessWidget {
  const _RentalPrice({
    //super.key,
    required TextEditingController rentalPriceController,
  }) : _rentalPriceController = rentalPriceController;

  final TextEditingController _rentalPriceController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _rentalPriceController,
      decoration: const InputDecoration(labelText: 'Precio de alquiler'),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _Capacity extends StatelessWidget {
  const _Capacity({
    //super.key,
    required TextEditingController capacityController,
  }) : _capacityController = capacityController;

  final TextEditingController _capacityController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _capacityController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Capacidad de personas'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _Address extends StatelessWidget {
  const _Address({
    //super.key, 
    required TextEditingController addressController
  }) : _addressController = addressController;

  final TextEditingController _addressController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(labelText: 'Dirección'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({
    //super.key,
    required TextEditingController descriptionController,
  }) : _descriptionController = descriptionController;

  final TextEditingController _descriptionController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(labelText: 'Descripción'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class _NameLocation extends StatelessWidget {
  const _NameLocation({
    //super.key,
    required TextEditingController nameLocationController,
  }) : _nameLocationController = nameLocationController;

  final TextEditingController _nameLocationController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _nameLocationController,
      decoration: const InputDecoration(labelText: 'Locación'),
      validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}
