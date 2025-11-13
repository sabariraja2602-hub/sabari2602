import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _employeeId;
  String? _employeeName;
  String? _position;

  String? get employeeId => _employeeId;
  String? get employeeName => _employeeName;
  String? get position => _position;

  void setEmployeeId(String id) {
    _employeeId = id;
    notifyListeners();
  }
  void setEmployeeName(String name) {
    _employeeName = name;
    notifyListeners();
  }
  void setPosition(String position) {
    _position = position;
    notifyListeners();
  }
  void clearUser() {
    _employeeId = null;
    _employeeName = null;
    _position = null;
    notifyListeners();
  }
}
