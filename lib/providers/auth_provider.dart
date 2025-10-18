import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  bool get isEmployee => _currentUser?.isEmployee ?? false;

  // Clear error
  void clearError() {
    _error = null;
    _notifyListenersSafely();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyListenersSafely();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    _notifyListenersSafely();
  }

  // Set user
  void _setUser(User? user) {
    _currentUser = user;
    _isLoading = false;
    _error = null;
    _notifyListenersSafely();
  }

  // Notify listeners safely: if called during build, defer to post frame.
  void _notifyListenersSafely() {
    final binding = WidgetsBinding.instance;
    // Defer all notifications to the next frame to guarantee we never call
    // notifyListeners during the widget build phase. This avoids the
    // "setState() or markNeedsBuild() called during build" FlutterError.
    binding.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (_) {}
    });
  }

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      clearError();

      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        _setError('Please fill in all fields');
        return false;
      }

      if (!AuthService.isValidEmail(email)) {
        _setError('Please enter a valid email address');
        return false;
      }

      // Attempt login
      final user = await AuthService.login(email, password);
      _setUser(user);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Register user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'employee',
    int? companyId,
  }) async {
    try {
      _setLoading(true);
      clearError();

      // Validate inputs
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _setError('Please fill in all fields');
        return false;
      }

      if (!AuthService.isValidName(name)) {
        _setError('Name must be at least 2 characters long');
        return false;
      }

      if (!AuthService.isValidEmail(email)) {
        _setError('Please enter a valid email address');
        return false;
      }

      if (!AuthService.isValidPassword(password)) {
        _setError('Password must be at least 6 characters long');
        return false;
      }

      // Attempt registration
      final user = await AuthService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        companyId: companyId,
      );
      
      _setUser(user);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      await AuthService.logout();
      _setUser(null);
    } catch (e) {
      _setError('Logout failed: $e');
    }
  }

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);
      
      if (await AuthService.isAuthenticated()) {
        // Try to get user profile to verify token is still valid
        try {
          final user = await AuthService.getProfile();
          _setUser(user);
        } catch (e) {
          // Token is invalid, clear it
          await AuthService.logout();
          _setUser(null);
        }
      } else {
        _setUser(null);
      }
    } catch (e) {
      _setError('Failed to check authentication status: $e');
      _setUser(null);
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;

    try {
      _setLoading(true);
      final user = await AuthService.getProfile();
      _setUser(user);
    } catch (e) {
      _setError('Failed to refresh profile: $e');
    }
  }

  // Update user data
  void updateUser(User user) {
    _setUser(user);
  }

  // Get user role display name
  String getRoleDisplayName() {
    if (_currentUser == null) return 'Guest';
    
    switch (_currentUser!.role) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'employee':
        return 'Employee';
      default:
        return 'User';
    }
  }

  // Check if user has permission for admin actions
  bool canAccessAdminFeatures() {
    return isAdmin || isSuperAdmin;
  }

  // Check if user has permission for super admin actions
  bool canAccessSuperAdminFeatures() {
    return isSuperAdmin;
  }
}

