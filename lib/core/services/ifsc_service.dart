import 'dart:convert';
import 'package:http/http.dart' as http;

class IfscService {
  static const String _baseUrl = 'https://ifsc.razorpay.com';

  /// Fetch bank details using IFSC code
  static Future<Map<String, dynamic>?> fetchBankDetails(String ifscCode) async {
    try {
      print('🔍 Fetching bank details for IFSC: $ifscCode');

      final response = await http.get(
        Uri.parse('$_baseUrl/$ifscCode'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 IFSC API Response Status: ${response.statusCode}');
      print('🔍 IFSC API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the response contains error information
        if (data['error'] != null) {
          print('❌ IFSC API Error: ${data['error']}');
          return null;
        }

        print('✅ IFSC API Success: Bank details fetched');
        return data;
      } else {
        print('❌ IFSC API Error: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ IFSC API Exception: $e');
      return null;
    }
  }

  /// Validate IFSC code format
  static bool isValidIfscFormat(String ifscCode) {
    // IFSC code should be 11 characters: 4 letters (bank code) + 7 alphanumeric
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return ifscRegex.hasMatch(ifscCode.toUpperCase());
  }

  /// Format IFSC code to uppercase
  static String formatIfscCode(String ifscCode) {
    return ifscCode.toUpperCase().trim();
  }
}
