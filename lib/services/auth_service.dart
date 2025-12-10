// services/auth_service.dart
import 'google_sheet_service.dart';

class AuthService {
  // Owner email always allowed
  static const String ownerEmail = "ferdyasino@gmail.com";

  /// Check if email is allowed
  /// Returns true if the email exists in the Google Sheet or is the owner
  static Future<bool> isEmailAllowed(String email) async {
    final lowerEmail = email.trim().toLowerCase();
    if (lowerEmail == ownerEmail.toLowerCase()) return true;

    final sheetService = GoogleSheetService();
    return await sheetService.isEmailAllowed(lowerEmail);
  }

  /// Get role for email
  static Future<String> getUserRole(String email) async {
    final lowerEmail = email.trim().toLowerCase();
    if (lowerEmail == ownerEmail.toLowerCase()) return "ADMIN";

    final sheetService = GoogleSheetService();
    return await sheetService.getUserRole(lowerEmail);
  }
}
