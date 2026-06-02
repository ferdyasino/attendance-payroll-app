import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiHelper {
  static Future<dynamic> postWithRedirect({
    required String url,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await http
        .post(
          Uri.parse(url),

          // KEEP JSON
          headers: {"Content-Type": "application/json"},

          body: jsonEncode(body),
        )
        .timeout(timeout);

    // DEBUG LOGS
    print("STATUS: ${response.statusCode}");
    print("HEADERS: ${response.headers}");
    print("BODY: ${response.body}");

    // HANDLE 302 REDIRECT
    if (response.statusCode == 302 ||
        response.statusCode == 301 ||
        response.statusCode == 303) {
      final redirectUrl = response.headers['location'];

      print("REDIRECT URL: $redirectUrl");

      if (redirectUrl == null) {
        throw Exception("Redirect URL missing");
      }

      final redirectedResponse =
          await http.get(Uri.parse(redirectUrl)).timeout(timeout);

      print("FINAL STATUS: ${redirectedResponse.statusCode}");

      print("FINAL HEADERS: ${redirectedResponse.headers}");

      print("FINAL BODY: ${redirectedResponse.body}");

      return _parseJsonResponse(redirectedResponse);
    }

    return _parseJsonResponse(response);
  }

  // =========================
  // OPTIONAL GET
  // =========================
  static Future<dynamic> getWithRedirect({
    required String url,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    Uri uri = Uri.parse(url);

    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    final response = await http.get(uri).timeout(timeout);

    print("STATUS: ${response.statusCode}");
    print("HEADERS: ${response.headers}");
    print("BODY: ${response.body}");

    // HANDLE REDIRECT
    if (response.statusCode == 302 ||
        response.statusCode == 301 ||
        response.statusCode == 303) {
      final redirectUrl = response.headers['location'];

      print("REDIRECT URL: $redirectUrl");

      if (redirectUrl == null) {
        throw Exception("Redirect URL missing");
      }

      final redirectedResponse =
          await http.get(Uri.parse(redirectUrl)).timeout(timeout);

      print("FINAL STATUS: ${redirectedResponse.statusCode}");

      print("FINAL BODY: ${redirectedResponse.body}");

      return _parseJsonResponse(redirectedResponse);
    }

    return _parseJsonResponse(response);
  }

  static dynamic _parseJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? "";

    print("PARSE CONTENT TYPE: $contentType");

    if (response.statusCode != 200) {
      throw Exception("Server returned ${response.statusCode}");
    }

    // DEBUG RAW RESPONSE
    print("RAW RESPONSE:");
    print(response.body);

    // DON'T REMOVE VALID HTML DEBUGGING
    if (!contentType.contains("application/json")) {
      print("WARNING: Response is not JSON");

      print("ACTUAL CONTENT TYPE: $contentType");

      throw Exception("Server did not return JSON");
    }

    final trimmed = response.body.trim();

    // SUPPORT OBJECT OR ARRAY
    if (!trimmed.startsWith("{") && !trimmed.startsWith("[")) {
      throw Exception("Invalid JSON response");
    }

    try {
      return jsonDecode(trimmed);
    } catch (e) {
      print("JSON PARSE ERROR: $e");

      throw Exception("Failed to parse JSON");
    }
  }
}
