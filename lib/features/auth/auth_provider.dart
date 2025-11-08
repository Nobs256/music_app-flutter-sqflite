import 'package:flutter/material.dart';
import 'package:musicapp/data/services/api_service.dart';

/// A provider class that manages the application's authentication state.
///
/// It handles user login, logout, and checking the initial authentication
/// status when the app starts. It uses [ChangeNotifier] to inform listening
/// widgets about state changes.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _userId;
  String? _username;
  bool _isLoading = true; // Start in a loading state

  /// Returns `true` if the user is currently authenticated.
  bool get isLoggedIn => _userId != null;

  /// The username of the authenticated user.
  String? get username => _username;

  AuthProvider() {
    // When the provider is created, immediately check the login status.
    checkLoginStatus();
  }

  /// Returns `true` while the provider is checking the initial login status.
  bool get isLoading => _isLoading;

  /// Checks secure storage for a valid JWT to determine the initial auth state.
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    // Check for a stored userId instead of a token.
    final userId = await _apiService.getUserId();
    if (userId != null) {
      _userId = userId;
      _username = await _apiService.getUsername(); // Get stored username
    } else {
      // If userId is null, ensure the state is logged out.
      _userId = null;
      _username = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Attempts to log in a user and updates the auth state on success.
  Future<bool> login(String username, String password) async {
    final response = await _apiService.login(username, password);
    if (response['error'] == false) {
      // On successful login, directly update the state with userId and username.
      // The ApiService is responsible for saving these to secure storage.
      _userId = response['userId']?.toString();
      _username = response['username']?.toString();
      notifyListeners(); // Notify listeners of the new authenticated state.
      return true;
    }
    return false;
  }

  /// Logs the user out and clears the authentication state.
  Future<void> logout() async {
    await _apiService.logout(); // Deletes token from storage via ApiService
    _userId = null;
    _username = null;
    notifyListeners();
  }
}
