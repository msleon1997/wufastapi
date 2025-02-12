import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {

  String? _token;

  String? get token => _token;

  Future<void> setToken(String token) async {
    _token = token;
    notifyListeners();
  }


}