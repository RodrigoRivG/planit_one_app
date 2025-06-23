// lib/screens/admin/tasks/tasks_form_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:planit_one_app/services/api_service.dart';
import 'package:intl/intl.dart';

class TasksFormScreen extends StatefulWidget {
  final int? taskId;
  
  const TasksFormScreen({super.key, this.taskId});

  @override
  State<TasksFormScreen> createState() => _TasksFormScreenState();
}

class _TasksFormScreenState extends State<TasksFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  String _selectedStatus = 'pendiente';
  int? _selectedEventId;
  List<int> _selectedStaffIds = [];
  
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _staff = [];
  
  final List<Map<String, String>> _statusOptions = [
    {'value': 'pendiente', 'label': 'Pendiente'},
    {'value': 'en_progreso', 'label': 'En Progreso'},
    {'value': 'completada', 'label': 'Completada'},
    {'value': 'cancelada', 'label': 'Cancelada'},
  ];

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.taskId != null;
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _cargarEventos(),
      _cargarStaff(),
    ]);
    
    if (_isEditing) {
      await _cargarDatosTarea();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarEventos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}events/');
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
          _eventos = data.map((item) => {
            'id': item['id'],
            'name': item['name'] ?? '',
          }).toList();
        });
      }
    } catch (e) {
      print('Error al cargar eventos: $e');
    }
  }

  Future<void> _cargarStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}staff/');
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
          _staff = data.map((item) => {
            'id': item['id'],
            'full_name': item['full_name'] ?? '',
            'email': item['email'] ?? '',
          }).toList();
        });
      }
    } catch (e) {
      print('Error al cargar staff: $e');
    }
  }

  Future<void> _cargarDatosTarea() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}tasks/${widget.taskId}/');
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
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _selectedStatus = data['status'] ?? 'pendiente';
          _selectedEventId = data['event'];
          
          // Cargar staff seleccionado
          _selectedStaffIds = (data['assigned_staff'] as List?)
              ?.map<int>((id) => id as int)
              .toList() ?? [];
          
          // Cargar fechas y horas
          if (data['start_datetime'] != null) {
            _startDateTime = DateTime.parse(data['start_datetime']);
            _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDateTime!);
            _startTimeController.text = DateFormat('HH:mm').format(_startDateTime!);
          }
          
          if (data['end_datetime'] != null) {
            _endDateTime = DateTime.parse(data['end_datetime']);
            _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDateTime!);
            _endTimeController.text = DateFormat('HH:mm').format(_endDateTime!);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos de la tarea: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFecha(TextEditingController controller, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
        if (isStart) {
          _startDateTime = _combinarFechaHora(picked, _startDateTime);
        } else {
          _endDateTime = _combinarFechaHora(picked, _endDateTime);
        }
      });
    }
  }

  Future<void> _seleccionarHora(TextEditingController controller, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
        if (isStart) {
          _startDateTime = _combinarFechaHora(_startDateTime, DateTime(
            2000, 1, 1, picked.hour, picked.minute
          ));
        } else {
          _endDateTime = _combinarFechaHora(_endDateTime, DateTime(
            2000, 1, 1, picked.hour, picked.minute
          ));
        }
      });
    }
  }

  DateTime? _combinarFechaHora(DateTime? fecha, DateTime? hora) {
    if (fecha == null) return null;
    if (hora == null) return fecha;
    
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
  }

  Future<void> _guardarTarea() async {
    if (_formKey.currentState!.validate()) {
      // Validar fechas
      if (_startDateTime == null || _endDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar fecha y hora de inicio y fin')),
        );
        return;
      }
      
      if (_startDateTime!.isAfter(_endDateTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fecha de inicio debe ser anterior a la fecha de fin')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token') ?? '';
        
        final Map<String, dynamic> body = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'start_datetime': _startDateTime!.toIso8601String(),
          'end_datetime': _endDateTime!.toIso8601String(),
          'status': _selectedStatus,
          'notes': _notesController.text.trim(),
          'assigned_staff': _selectedStaffIds,
        };
        
        if (_selectedEventId != null) {
          body['event'] = _selectedEventId;
        }

        final Uri url;
        final http.Response response;
        
        if (_isEditing) {
          url = Uri.parse('${baseUrl}tasks/${widget.taskId}/');
          response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          );
        } else {
          url = Uri.parse('${baseUrl}tasks/');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Tarea actualizada exitosamente' : 'Tarea creada exitosamente')),
          );
          Navigator.pop(context);
        } else {
          print('Error al ${_isEditing ? 'actualizar' : 'crear'} tarea: ${response.statusCode}');
          print('Respuesta: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al ${_isEditing ? 'actualizar' : 'crear'} tarea')),
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

  void _toggleStaff(int staffId) {
    setState(() {
      if (_selectedStaffIds.contains(staffId)) {
        _selectedStaffIds.remove(staffId);
      } else {
        _selectedStaffIds.add(staffId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: Text(_isEditing ? 'Editar Tarea' : 'Nueva Tarea'),
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
                    _buildBasicFields(),
                    const SizedBox(height: 24),
                    _buildDateTimeFields(),
                    const SizedBox(height: 24),
                    _buildEventField(),
                    const SizedBox(height: 24),
                    _buildStatusField(),
                    const SizedBox(height: 24),
                    _buildStaffField(),
                    const SizedBox(height: 24),
                    _buildNotasField(),
                    const SizedBox(height: 24),
                    _buildButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        _CustomTextFormField(
          controller: _titleController,
          label: 'Título de la tarea *',
          validator: (value) => value?.isEmpty == true ? 'Campo obligatorio' : null,
        ),
        const SizedBox(height: 16),
        _CustomTextFormField(
          controller: _descriptionController,
          label: 'Descripción *',
          maxLines: 3,
          validator: (value) => value?.isEmpty == true ? 'Campo obligatorio' : null,
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha y Hora',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Fecha y hora de inicio
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de inicio *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _seleccionarFecha(_startDateController, true),
                validator: (value) => value?.isEmpty == true ? 'Obligatorio' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Hora de inicio *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _seleccionarHora(_startTimeController, true),
                validator: (value) => value?.isEmpty == true ? 'Obligatorio' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Fecha y hora de fin
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de fin *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _seleccionarFecha(_endDateController, false),
                validator: (value) => value?.isEmpty == true ? 'Obligatorio' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(
                  labelText: 'Hora de fin *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _seleccionarHora(_endTimeController, false),
                validator: (value) => value?.isEmpty == true ? 'Obligatorio' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evento (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedEventId,
          decoration: const InputDecoration(
            labelText: 'Seleccionar evento',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Sin evento'),
            ),
            ..._eventos.map((evento) => DropdownMenuItem<int>(
              value: evento['id'],
              child: Text(evento['name']),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedEventId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Estado de la tarea',
            border: OutlineInputBorder(),
          ),
          items: _statusOptions.map((status) => DropdownMenuItem<String>(
            value: status['value'],
            child: Text(status['label']!),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStaffField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal asignado',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_staff.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay personal disponible'),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: _staff.map((staff) {
                final bool isSelected = _selectedStaffIds.contains(staff['id']);
                return CheckboxListTile(
                  title: Text(staff['full_name']),
                  subtitle: Text(staff['email']),
                  value: isSelected,
                  onChanged: (_) => _toggleStaff(staff['id']),
                  activeColor: Colors.blue,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNotasField() {
    return _CustomTextFormField(
      controller: _notesController,
      label: 'Notas adicionales',
      maxLines: 3,
      required: false,
    );
  }

  Widget _buildButtons() {
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
            style: TextStyle(color: Colors.lightBlue),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardarTarea,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[400],
            minimumSize: const Size(120, 40),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'GUARDAR',
                  style: TextStyle(color: Colors.white),
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
  final String? Function(String?)? validator;

  const _CustomTextFormField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.required = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (required 
          ? (value) => value?.isEmpty == true ? 'Campo obligatorio' : null 
          : null),
    );
  }
}