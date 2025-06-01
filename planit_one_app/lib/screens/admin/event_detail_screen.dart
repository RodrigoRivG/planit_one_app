import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

/// Pantalla de detalle y edición de un evento
class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;
  final List<String> _statusOptions = [
    'scheduled',
    'in_progress',
    'completed',
    'cancelled',
  ];

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _locations = [];
  int? _selectedServiceId;
  int? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event['name']);
    _descriptionController =
        TextEditingController(text: widget.event['description']);
    _startDate = DateTime.parse(widget.event['start_date']);
    _endDate = DateTime.parse(widget.event['end_date']);
    _status = widget.event['status'];
    _selectedServiceId = widget.event['service']?['id'];
    _selectedLocationId = widget.event['location']?['id'];
    _fetchServices();
    _fetchLocations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final resp = await http.get(
      Uri.parse('${baseUrl}services/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      setState(() {
        _services = data
            .map<Map<String, dynamic>>(
                (e) => {'id': e['id'] as int, 'name': e['name'] as String})
            .toList();
      });
    }
  }

  Future<void> _fetchLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final resp = await http.get(
      Uri.parse('${baseUrl}locations/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      setState(() {
        _locations = data
            .map<Map<String, dynamic>>(
                (e) => {'id': e['id'] as int, 'name': e['name'] as String})
            .toList();
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
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
    final selected = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) _startDate = selected;
      else _endDate = selected;
    });
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final url =
        Uri.parse('${baseUrl}events/${widget.event['id']}/');

    // Enviar service_ids y location_id según lo que exige el backend
    final body = jsonEncode({
      'name': _nameController.text,
      'description': _descriptionController.text,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'status': _status,
      'service_ids': _selectedServiceId != null ? [_selectedServiceId] : [],
      'location_id': _selectedLocationId,
    });

    final resp = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      final errorMsg = resp.body;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${resp.statusCode}: $errorMsg'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Evento'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration:
                  InputDecoration(labelText: 'Nombre del evento'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(
                  "Fecha de inicio: ${DateFormat('yyyy-MM-dd HH:mm').format(_startDate)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, true),
            ),
            ListTile(
              title: Text(
                  "Fecha de fin: ${DateFormat('yyyy-MM-dd HH:mm').format(_endDate)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context, false),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: 'Estado'),
              items: _statusOptions
                  .map<DropdownMenuItem<String>>(
                      (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s.toUpperCase()),
                          ))
                  .toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedServiceId,
              decoration: InputDecoration(labelText: 'Servicio'),
              items: _services
                  .map<DropdownMenuItem<int>>(
                      (s) => DropdownMenuItem<int>(
                            value: s['id'] as int,
                            child: Text(s['name'] as String),
                          ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedServiceId = val),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedLocationId,
              decoration: InputDecoration(labelText: 'Locación'),
              items: _locations
                  .map<DropdownMenuItem<int>>(
                      (l) => DropdownMenuItem<int>(
                            value: l['id'] as int,
                            child: Text(l['name'] as String),
                          ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedLocationId = val),
            ),
          ],
        ),
      ),
    );
  }
}
