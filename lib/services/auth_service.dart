import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  // Login user
  static Future<User> login(String email, String password) async {
    try {
      final response = await ApiService.post(
        Constants.loginEndpoint,
        body: {
          'email': email,
          'password': password,
        },
        includeAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final user = User.fromJson(data['user']);
        final token = data['token'];
        
        // Save token
        await saveToken(token);
        
        // Return user with token
        return user.copyWith(token: token);
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register new user
  static Future<User> register({
    required String name,
    required String email,
    required String password,
    String role = 'employee',
    int? companyId,
  }) async {
    try {
      final response = await ApiService.post(
        Constants.registerEndpoint,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (companyId != null) 'companyId': companyId,
        },
        includeAuth: false,
      );

      if (response['success'] == true && response['data'] != null) {
        final user = User.fromJson(response['data']);
        return user;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Get current user profile
  static Future<User> getProfile() async {
    try {
      final response = await ApiService.get(Constants.profileEndpoint);
      
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  // Save JWT token
  static Future<void> saveToken(String token) async {
    await ApiService.saveToken(token);
  }

  // Get stored JWT token
  static Future<String?> getToken() async {
    return await ApiService.getToken();
  }

  // Clear stored token
  static Future<void> clearToken() async {
    await ApiService.clearToken();
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await ApiService.isAuthenticated();
  }

  // Logout user
  static Future<void> logout() async {
    try {
      await clearToken();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Validate name
  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  // Get available roles
  static List<String> getAvailableRoles() {
    return [
      Constants.roleEmployee,
      Constants.roleAdmin,
      Constants.roleSuperadmin,
    ];
  }

  // Check server connectivity
  static Future<bool> checkServerHealth() async {
    return await ApiService.checkServerHealth();
  }
}

