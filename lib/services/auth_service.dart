// services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sheet_service.dart';

class AuthService {
  // Google Sign-In instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Owner email always allowed
  static const String ownerEmail = "ferdyasino@gmail.com";

  /// Sign in with Google
  /// Returns email if authorized, or null if denied
  static Future<String?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final email = account.email.trim().toLowerCase();

      // Owner bypass
      if (email == ownerEmail.toLowerCase()) return email;

      // Check Google Sheet
      final sheetService = GoogleSheetService();
      final allowed = await sheetService.isEmailAllowed(email);

      if (!allowed) {
        await _googleSignIn.signOut();
        return null;
      }

      return email;
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Check if signed in
  static Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Get current signed-in user's email
  static String? getCurrentUserEmail() {
    return _googleSignIn.currentUser?.email;
  }

  /// Get current user's role from Google Sheet
  static Future<String> getUserRole(String email) async {
    final sheetService = GoogleSheetService();
    return sheetService.getUserRole(email);
  }
}
