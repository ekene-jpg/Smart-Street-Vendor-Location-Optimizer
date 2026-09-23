import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();
  AppUser? currentUser;

  bool get isLoggedIn => currentUser != null;

  void setUser(AppUser user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    currentUser = null;
    notifyListeners();
  }
}
