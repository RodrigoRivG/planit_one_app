// lib/screens/admin/tasks/tasks_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:planit_one_app/screens/admin/tareas/tasks_form_screen.dart';
import 'package:planit_one_app/services/api_service.dart';
import 'package:intl/intl.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Todas'},
    {'value': 'pendiente', 'label': 'Pendiente'},
    {'value': 'en_progreso', 'label': 'En Progreso'},
    {'value': 'completada', 'label': 'Completada'},
    {'value': 'cancelada', 'label': 'Cancelada'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTareas() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}tasks/');
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
          _tasks = data.map((item) => {
            'id': item['id'],
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'start_datetime': item['start_datetime'] ?? '',
            'end_datetime': item['end_datetime'] ?? '',
            'event_name': item['event_name'] ?? 'Sin evento',
            'assigned_staff_names': item['assigned_staff_names'] ?? '',
            'status': item['status'] ?? 'pendiente',
            'status_display': item['status_display'] ?? '',
            'notes': item['notes'] ?? '',
          }).toList();
          _isLoading = false;
        });
      } else {
        print('Error al cargar tareas: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarTareas(String query) async {
    if (query.isEmpty) {
      _cargarTareas();
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}tasks/search/?q=$query');
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
          _tasks = data.map((item) => {
            'id': item['id'],
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'start_datetime': item['start_datetime'] ?? '',
            'end_datetime': item['end_datetime'] ?? '',
            'event_name': item['event_name'] ?? 'Sin evento',
            'assigned_staff_names': item['assigned_staff_names'] ?? '',
            'status': item['status'] ?? 'pendiente',
            'status_display': item['status_display'] ?? '',
            'notes': item['notes'] ?? '',
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error de conexión en búsqueda: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _filtrarPorEstado(String status) async {
    setState(() {
      _selectedStatus = status;
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      String url;
      if (status == 'all') {
        url = '${baseUrl}tasks/';
      } else {
        url = '${baseUrl}tasks/by_status/?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _tasks = data.map((item) => {
            'id': item['id'],
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'start_datetime': item['start_datetime'] ?? '',
            'end_datetime': item['end_datetime'] ?? '',
            'event_name': item['event_name'] ?? 'Sin evento',
            'assigned_staff_names': item['assigned_staff_names'] ?? '',
            'status': item['status'] ?? 'pendiente',
            'status_display': item['status_display'] ?? '',
            'notes': item['notes'] ?? '',
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al filtrar tareas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _crearTarea() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TasksFormScreen(),
      ),
    ).then((_) => _cargarTareas());
  }

  void _editarTarea(int taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TasksFormScreen(taskId: taskId),
      ),
    ).then((_) => _cargarTareas());
  }

  Future<void> _eliminarTarea(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final url = Uri.parse('${baseUrl}tasks/$taskId/');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada correctamente')),
        );
        _cargarTareas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la tarea: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _confirmarEliminar(int taskId, String title) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de eliminar la tarea "$title"?'),
                const Text('Esta acción no se puede deshacer.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarTarea(taskId);
              },
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'en_progreso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text('Tareas'),
        actions: [
          IconButton(
            onPressed: _crearTarea,
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Tarea',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
                ? const Center(child: Text('No hay tareas disponibles'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildTaskCard(task),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar tareas...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _cargarTareas();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            onSubmitted: _buscarTareas,
          ),
          const SizedBox(height: 16),
          // Filtro por estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((option) {
                final isSelected = _selectedStatus == option['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(option['label']!),
                    selected: isSelected,
                    onSelected: (_) => _filtrarPorEstado(option['value']!),
                    selectedColor: Colors.blue[100],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (task['description']?.isNotEmpty == true)
                    Text(
                      task['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(task['status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task['status_display'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTaskInfo(task),
        const SizedBox(height: 12),
        _buildTaskActions(task),
      ],
    );
  }

  Widget _buildTaskInfo(Map<String, dynamic> task) {
    return Column(
      children: [
        _buildInfoRow(Icons.event, 'Evento', task['event_name']),
        if (task['assigned_staff_names']?.isNotEmpty == true)
          _buildInfoRow(Icons.people, 'Asignado a', task['assigned_staff_names']),
        _buildInfoRow(Icons.schedule, 'Inicio', _formatDateTime(task['start_datetime'])),
        _buildInfoRow(Icons.schedule, 'Fin', _formatDateTime(task['end_datetime'])),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskActions(Map<String, dynamic> task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _editarTarea(task['id']),
          child: const Text('EDITAR'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _confirmarEliminar(task['id'], task['title']),
          child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}