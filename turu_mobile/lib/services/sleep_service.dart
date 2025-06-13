// TURU-Flutter
// Lokasi: lib/services/sleep_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class SleepService {
  // Ganti IP address sesuai dengan IP lokal mesin Anda.
  // Jika menggunakan emulator Android, 10.0.2.2 biasanya merujuk ke localhost mesin host.
  final String _baseUrl = "http://192.168.18.36/api";

  Future<List<dynamic>> getSleepHistory(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/datatidur/$userId'));

      if (response.statusCode == 200) {
        // Jika server mengembalikan respons OK, parse JSON.
        // Backend akan mengembalikan list kosong '[]' jika tidak ada data.
        return json.decode(response.body);
      } else {
        // Jika server tidak mengembalikan 200 OK,
        // kembalikan list kosong agar UI bisa menampilkan data dummy.
        print('Failed to load sleep history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Jika terjadi error (misal: tidak ada koneksi),
      // kembalikan list kosong.
      print('Error fetching sleep history: $e');
      return [];
    }
  }
}