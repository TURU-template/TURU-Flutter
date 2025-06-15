import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:turu_mobile/services/auth.dart'; // Import AuthService untuk mendapatkan baseUrl

class SleepService {
  final String _baseUrl = AuthService.getBaseUrl(); // Ambil base URL dari AuthService

  Map<String, String> _getApiHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Future<List<dynamic>> getSleepHistory(int userId) async {
    final url = Uri.parse('$_baseUrl/api/sleep-records/history/$userId');
    log('DEBUG_SLEEP_SERVICE: Fetching sleep history from: $url');
    try {
      final response = await http.get(url, headers: _getApiHeaders()).timeout(const Duration(seconds: 10));

      log('DEBUG_SLEEP_SERVICE: Response Status for history: ${response.statusCode}');
      log('DEBUG_SLEEP_SERVICE: Response Body for history (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        // Jika body kosong atau hanya berisi [], kembalikan list kosong
        if (response.body.isEmpty || response.body == '[]') {
          return [];
        }
        return jsonDecode(response.body);
      } else if (response.statusCode == 204) {
        // 204 No Content berarti tidak ada data
        return [];
      } else {
        log('ERROR_SLEEP_SERVICE: Failed to load sleep history: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load sleep history: ${response.statusCode}');
      }
    } catch (e) {
      log('FATAL_SLEEP_SERVICE: Error fetching sleep history: $e');
      rethrow; // Lempar kembali error agar bisa ditangkap di UI
    }
  }

  // Anda bisa menambahkan metode lain di sini jika diperlukan,
  // misalnya untuk memanggil API start, end, manual sleep, dll.
}