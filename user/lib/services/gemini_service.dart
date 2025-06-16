import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyCw261Qzj6nC6imJnj8bXmIw6fILXtnY1Q'; // Sebaiknya pindahkan ke file rahasia
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static Future<String> getReminderMessage(String medicineName, String doseTime) async {
    final prompt = '''
Buatkan pesan pengingat minum obat dengan nada ramah untuk obat $medicineName yang harus diminum pada pukul $doseTime. Gunakan bahasa Indonesia. Singkat dan jelas.
''';

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Waktunya minum obat $medicineName!';
      } else {
        print('API Gemini error: ${response.body}');
        return 'Jangan lupa minum obat $medicineName!';
      }
    } catch (e) {
      print('Error Gemini API: $e');
      return 'Waktunya minum obat $medicineName!';
    }
  }
}
