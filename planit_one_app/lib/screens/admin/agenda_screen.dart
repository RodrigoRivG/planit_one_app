import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit_one_app/screens/admin/event_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// Modelo Event extendido
class Event {
  final int id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String image;
  final int? serviceId;
  final String? serviceName;
  final int? locationId;
  final String? locationName;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.image,
    this.serviceId,
    this.serviceName,
    this.locationId,
    this.locationName,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      image: json['image'] ?? '',
      serviceId: json['service']?['id'],
      serviceName: json['service']?['name'],
      locationId: json['location']?['id'],
      locationName: json['location']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'service': serviceId,
      'location': locationId,
      'image': image,
    };
  }
}

// Pantalla de Agenda
class AgendaScreen extends StatefulWidget {
  @override
  _AgendaScreenState createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<Event> _events = [];
  bool _loading = true;
  String _filterStatus = 'all';

  Future<void> fetchEvents() async {
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
      List<Event> loaded = data.map((e) => Event.fromJson(e)).toList();
      loaded.sort((a, b) => b.startDate.compareTo(a.startDate));
      setState(() {
        _events = loaded;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filterStatus == 'all'
        ? _events
        : _events.where((e) => e.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda de Eventos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'all', child: Text('Todos')),
              PopupMenuItem(value: 'scheduled', child: Text('Programado')),
              PopupMenuItem(value: 'in_progress', child: Text('En curso')),
              PopupMenuItem(value: 'completed', child: Text('Finalizado')),
              PopupMenuItem(value: 'cancelled', child: Text('Cancelado')),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : filteredEvents.isEmpty
              ? Center(child: Text('No hay eventos'))
              : ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (ctx, i) {
                    final event = filteredEvents[i];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: event.image.isNotEmpty
                            ? Image.network(event.image, width: 60, fit: BoxFit.cover)
                            : Icon(Icons.event),
                        title: Text(event.name),
                        subtitle: Text(
                          '${event.status.toUpperCase()} • ${DateFormat('yyyy-MM-dd HH:mm').format(event.startDate.toLocal())}\n'
                          'Servicio: ${event.serviceName ?? '-'} • Locación: ${event.locationName ?? '-'}',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: {
                                'id': event.id,
                                'name': event.name,
                                'description': event.description,
                                'start_date': event.startDate.toIso8601String(),
                                'end_date': event.endDate.toIso8601String(),
                                'status': event.status,
                                'image': event.image,
                                'service': {
                                  'id': event.serviceId,
                                  'name': event.serviceName,
                                },
                                'location': {
                                  'id': event.locationId,
                                  'name': event.locationName,
                                },
                              }),
                            ),
                          ).then((updated) {
                            if (updated == true) fetchEvents();
                          });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
