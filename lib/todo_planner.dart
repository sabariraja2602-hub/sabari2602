import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'sidebar.dart';
import 'user_provider.dart';

class ToDoPlanner extends StatefulWidget {
  const ToDoPlanner({super.key});

  @override
  State<ToDoPlanner> createState() => _ToDoPlannerState();
}

class _ToDoPlannerState extends State<ToDoPlanner> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? _currentTaskData;

  // Map of date → tasks
  final Map<String, List<Map<String, String>>> _tasksByDate = {};

  final statusOptions = ['Yet to start', 'In progress', 'Completed'];
  final workStatusOptions = [
    'WFH',
    'WFO',
    'Casual leave',
    'Sick leave',
    'Sad leave',
    'Holiday',
  ];

  final String baseUrl = 'https://sabari2602.onrender.com/todo_planner';

  @override
  void initState() {
    super.initState();
    _fetchAllTasks();
  }

  /// ✅ Fetch ALL tasks for this employee, grouped by date
  Future<void> _fetchAllTasks() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = userProvider.employeeId ?? '';
      if (employeeId.isEmpty) return;

      final res = await http.get(Uri.parse('$baseUrl/todo/$employeeId'));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        setState(() {
          _tasksByDate.clear();
          data.forEach((date, taskData) {
            _tasksByDate[date] = (taskData['tasks'] as List)
                .map<Map<String, String>>(
                  (e) => {
                    'item': e['item']?.toString() ?? '',
                    'eta': e['eta']?.toString() ?? '',
                    'status': e['status']?.toString() ?? '',
                  },
                )
                .toList();
          });
        });
      }
    } catch (e) {
      print('Fetch all tasks error: $e');
    }
  }

  /// ✅ Fetch one day’s task
  Future<void> _fetchTask(String date) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = userProvider.employeeId ?? '';

      if (employeeId.isEmpty) return;

      final res = await http.get(Uri.parse('$baseUrl/todo/$employeeId/$date'));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        setState(() {
          _currentTaskData = data;
          _tasksByDate[date] = (data['tasks'] as List)
              .map<Map<String, String>>(
                (e) => {
                  'item': e['item']?.toString() ?? '',
                  'eta': e['eta']?.toString() ?? '',
                  'status': e['status']?.toString() ?? '',
                },
              )
              .toList();
        });
      } else {
        setState(() {
          _currentTaskData = null;
          _tasksByDate.remove(date);
        });
      }
    } catch (e) {
      print('Fetch error: $e');
    }
  }

  /// ✅ Save task
  Future<void> _saveTask(
    String date,
    String workStatus,
    List<Map<String, String>> tasks,
  ) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = userProvider.employeeId ?? '';

      if (employeeId.isEmpty) return;

      await http.post(
        Uri.parse('$baseUrl/todo/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'date': date,
          'workStatus': workStatus,
          'tasks': tasks,
        }),
      );

      await _fetchTask(date); // refresh task
      setState(() {
        _selectedDay = DateTime.parse(date);
      });
    } catch (e) {
      print('Save error: $e');
    }
  }

  /// Show add/edit bottom sheet
  void _showAddOrEditDialog(DateTime date, {bool isEdit = false}) {
    String selectedWorkStatus = isEdit && _currentTaskData != null
        ? _currentTaskData!['workStatus']
        : workStatusOptions[0];

    List<Map<String, String>> workItems = [];

    if (isEdit && _currentTaskData != null) {
      workItems = List<Map<String, String>>.from(
        (_currentTaskData!['tasks'] as List).map<Map<String, String>>(
          (e) => {
            'item': e['item'].toString(),
            'eta': e['eta'].toString(),
            'status': e['status'].toString(),
          },
        ),
      );
    } else {
      workItems = [
        {'item': '', 'eta': '', 'status': ''},
      ];
    }

    showModalBottomSheet(
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isEdit ? 'Edit' : 'Add'} Tasks',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedWorkStatus,
                      dropdownColor: Colors.black,
                      items: workStatusOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedWorkStatus = val!),
                      decoration: const InputDecoration(
                        labelText: 'Work Status',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...workItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      return Column(
                        children: [
                          TextFormField(
                            initialValue: entry.value['item'],
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Work Item',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            onChanged: (val) => workItems[index]['item'] = val,
                          ),
                          TextFormField(
                            initialValue: entry.value['eta'],
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'ETA',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            onChanged: (val) => workItems[index]['eta'] = val,
                          ),
                          DropdownButtonFormField<String>(
                            dropdownColor: Colors.black,
                            value:
                                workItems[index]['status']?.isNotEmpty == true
                                ? workItems[index]['status']
                                : null,
                            items: statusOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setModalState(
                              () => workItems[index]['status'] = val!,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setModalState(() => workItems.removeAt(index)),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (workItems.every(
                          (task) =>
                              task['item']!.isNotEmpty &&
                              task['eta']!.isNotEmpty &&
                              task['status']!.isNotEmpty,
                        )) {
                          String dateStr = date
                              .toIso8601String()
                              .split('T')
                              .first;
                          await _saveTask(
                            dateStr,
                            selectedWorkStatus,
                            workItems,
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fill all details!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(isEdit ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskBox() {
    if (_selectedDay == null || _currentTaskData == null)
      return const SizedBox();

    final selectedDateStr = _selectedDay!.toIso8601String().split('T').first;
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    bool isTodayOrFuture = selectedDateStr.compareTo(todayStr) >= 0;
    final data = _currentTaskData!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Status: ${data['workStatus']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List<Map<String, dynamic>>.from(data['tasks']).map(
            (task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${task['item']} | ETA: ${task['eta']} | Status: ${task['status']}',
              ),
            ),
          ),
          if (isTodayOrFuture)
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () =>
                    _showAddOrEditDialog(_selectedDay!, isEdit: true),
                child: const Text('Edit'),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final dateStr = day.toIso8601String().split('T').first;
    return _tasksByDate[dateStr] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'To-Do Planner',
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                final selectedDateStr = selectedDay
                    .toIso8601String()
                    .split('T')
                    .first;
                await _fetchTask(selectedDateStr);

                final todayStr = DateTime.now()
                    .toIso8601String()
                    .split('T')
                    .first;
                if (selectedDateStr.compareTo(todayStr) >= 0 &&
                    _currentTaskData == null) {
                  _showAddOrEditDialog(selectedDay, isEdit: false);
                }
              },
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white),
                selectedDecoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ),
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        height: 3,
                        width: 20,
                        color: Colors.purpleAccent,
                      ),
                    );
                  }
                  return null;
                },
              ),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  if (_selectedDay != null && _currentTaskData != null)
                    _buildTaskBox(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
