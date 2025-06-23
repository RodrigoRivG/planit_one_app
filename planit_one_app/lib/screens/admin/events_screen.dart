import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final url = Uri.parse('${baseUrl}events/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _events = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _openEventForm({Map<String, dynamic>? event}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventFormScreen(event: event),
      ),
    );
    if (result == true) _fetchEvents();
  }

  Future<void> _deleteEvent(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final url = Uri.parse('${baseUrl}events/$eventId/');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado correctamente')),
      );
      _fetchEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el evento: \\${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('Creación de eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear evento',
            onPressed: () => _openEventForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No hay eventos creados'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Locación')),
                      DataColumn(label: Text('Servicios/Paquete')),
                      DataColumn(label: Text('Usuario')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: _events.map((event) {
                      final fecha = event['start_date'] != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(event['start_date']))
                          : '-';
                      final locacion = event['location']?['name'] ?? '-';
                      final servicios = event['is_package'] == true
                          ? (event['package']?['name'] ?? '-')
                          : (event['services'] as List?)?.map((s) => s['name']).join(', ') ?? '-';
                      final usuario = event['owner']?['username'] ?? '-';
                      return DataRow(cells: [
                        DataCell(Text(event['name'] ?? '-')),
                        DataCell(Text(fecha)),
                        DataCell(Text(locacion)),
                        DataCell(Text(servicios)),
                        DataCell(Text(usuario)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openEventForm(event: event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirmar eliminación'),
                                    content: const Text('¿Estás seguro de eliminar este evento?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) _deleteEvent(event['id']);
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
    );
  }
}

// ----------- FORMULARIO DE EVENTO (2 PASOS) -----------
class EventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? event;
  const EventFormScreen({Key? key, this.event}) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();

  // Paso 1
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;
  late TextEditingController _attendeeController;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedLocationId;
  bool _isPackage = false;
  int? _selectedPackageId;
  List<int> _selectedServiceIds = [];

  // Paso 2 - campos para nuevo usuario
  final _userFormKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _userType = 'customer';

  // // Datos auxiliares
  // List<Map<String, dynamic>> _locations = [];
  // List<Map<String, dynamic>> _services = [];
  // List<Map<String, dynamic>> _packages = [];
  // bool _loading = false;
// Datos auxiliares
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _services  = [];
  List<Map<String, dynamic>> _packages  = [];
  List<Map<String, dynamic>> _users     = [];   // ← declara esta lista
  bool _loading                     = false;
  int? _selectedUserId              = null;    // ← declara este id

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.event?['description'] ?? '');
    _imageController = TextEditingController(text: widget.event?['image'] ?? '');
    _attendeeController = TextEditingController(text: widget.event?['attendee_count']?.toString() ?? '');
    _startDate = widget.event?['start_date'] != null ? DateTime.parse(widget.event!['start_date']) : null;
    _endDate = widget.event?['end_date'] != null ? DateTime.parse(widget.event!['end_date']) : null;
    _selectedLocationId = widget.event?['location']?['id'];
    _isPackage = widget.event?['is_package'] ?? false;
    _selectedPackageId = widget.event?['package']?['id'];
    _selectedServiceIds = widget.event?['services'] != null
        ? List<int>.from((widget.event!['services'] as List).map((s) => s['id']))
        : [];
    _selectedUserId = widget.event?['owner']?['id'];
    _fetchAuxData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _attendeeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuxData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    // Locations
    final locResp = await http.get(Uri.parse('${baseUrl}locations/'), headers: headers);
    if (locResp.statusCode == 200) {
      _locations = List<Map<String, dynamic>>.from(jsonDecode(locResp.body));
    }
    // Services
    final servResp = await http.get(Uri.parse('${baseUrl}services/'), headers: headers);
    if (servResp.statusCode == 200) {
      _services = List<Map<String, dynamic>>.from(jsonDecode(servResp.body));
    }
    // Packages
    final packResp = await http.get(Uri.parse('${baseUrl}packages/'), headers: headers);
    if (packResp.statusCode == 200) {
      _packages = List<Map<String, dynamic>>.from(jsonDecode(packResp.body));
    }
    // Users
    final userResp = await http.get(Uri.parse('${baseUrl}users/'), headers: headers);
    if (userResp.statusCode == 200) {
      _users = List<Map<String, dynamic>>.from(jsonDecode(userResp.body));
    }
    setState(() => _loading = false);
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) _startDate = selected;
      else _endDate = selected;
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || !_userFormKey.currentState!.validate()) return;
    if (_passwordController.text != _password2Controller.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
      'image': _imageController.text.trim(),
      'attendee_count': int.tryParse(_attendeeController.text.trim()) ?? 0,
      'location_id': _selectedLocationId,
      'is_package': _isPackage,
      'service_ids': _isPackage ? [] : _selectedServiceIds,
      'package_id': _isPackage ? _selectedPackageId : null,
      'owner_data': {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'password': _passwordController.text,
        'password2': _password2Controller.text,
        'user_type': _userType,
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      },
    };
    //   // Sólo si el usuario eligió un paquete lo agrego
    // if (_isPackage && _selectedPackageId != null) {
    //   body['package_id'] = _selectedPackageId;
    // }
    final isEdit = widget.event != null;
    final url = isEdit
        ? Uri.parse('${baseUrl}events/${widget.event!['id']}/')
        : Uri.parse('${baseUrl}events/');
    final response = isEdit
        ? await http.put(url, headers: headers, body: jsonEncode(body))
        : await http.post(url, headers: headers, body: jsonEncode(body));
    setState(() => _loading = false);
    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: \\${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: Text(widget.event == null ? 'Crear Evento' : 'Editar Evento'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _step,
              onStepContinue: () {
                if (_step == 0) {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _step = 1);
                  }
                } else {
                  _saveEvent();
                }
              },
              onStepCancel: () {
                if (_step == 0) {
                  Navigator.pop(context);
                } else {
                  setState(() => _step = 0);
                }
              },
              steps: [
                Step(
                  title: const Text('Datos del Evento'),
                  isActive: _step == 0,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Descripción'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(_startDate == null
                                  ? 'Fecha inicio: no seleccionada'
                                  : 'Inicio: \\${DateFormat('yyyy-MM-dd HH:mm').format(_startDate!)}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDateTime(context, true),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(_endDate == null
                                  ? 'Fecha fin: no seleccionada'
                                  : 'Fin: \\${DateFormat('yyyy-MM-dd HH:mm').format(_endDate!)}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDateTime(context, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _attendeeController,
                          decoration: const InputDecoration(labelText: 'Nº de asistentes'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _imageController,
                          decoration: const InputDecoration(labelText: 'URL de imagen'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedLocationId,
                          decoration: const InputDecoration(labelText: 'Locación'),
                          items: _locations
                              .map((l) => DropdownMenuItem<int>(
                                    value: l['id'],
                                    child: Text(l['name'] ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedLocationId = v),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('¿Usar paquete?'),
                          value: _isPackage,
                          onChanged: (v) => setState(() => _isPackage = v),
                        ),
                        if (_isPackage)
                          DropdownButtonFormField<int>(
                            value: _selectedPackageId,
                            decoration: const InputDecoration(labelText: 'Paquete'),
                            items: _packages
                                .map((p) => DropdownMenuItem<int>(
                                      value: p['id'],
                                      child: Text(p['name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedPackageId = v),
                          )
                        else
                          DropdownButtonFormField<List<int>>(
                            value: _selectedServiceIds.isEmpty ? null : _selectedServiceIds,
                            decoration: const InputDecoration(labelText: 'Servicios'),
                            items: _services
                                .map((s) => DropdownMenuItem<List<int>>(
                                      value: [s['id']],
                                      child: Text(s['name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedServiceIds = v);
                              }
                            },
                            isExpanded: true,
                          ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Datos del Usuario'),
                  isActive: _step == 1,
                  content: Form(
                    key: _userFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'Usuario *'),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email *'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final emailRegex = RegExp(r'^.+@.+\..+');
                            if (!emailRegex.hasMatch(v)) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Nombre *'),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Apellido *'),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _userType,
                          decoration: const InputDecoration(labelText: 'Tipo de usuario *'),
                          items: const [
                            DropdownMenuItem(value: 'superadmin', child: Text('Administrador Global')),
                            DropdownMenuItem(value: 'admin', child: Text('Administrador de Empresa')),
                            DropdownMenuItem(value: 'staff', child: Text('Personal')),
                            DropdownMenuItem(value: 'customer', child: Text('Cliente')),
                          ],
                          onChanged: (v) => setState(() => _userType = v ?? 'customer'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Teléfono'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Dirección'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Contraseña *'),
                          obscureText: true,
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password2Controller,
                          decoration: const InputDecoration(labelText: 'Repetir Contraseña *'),
                          obscureText: true,
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
