import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // PENTING: Menyimpan API Key langsung di kode sumber sangat tidak disarankan
  // untuk aplikasi produksi karena masalah keamanan. API Key dapat terekspos.
  // Gunakan metode manajemen rahasia yang lebih aman untuk produksi.
  static const String _apiKey = 'AIzaSyDrSa3ibXCH14987e7zZTZ04QkbelSsijc'; // Ganti dengan API Key Anda yang sebenarnya

  // Inisialisasi model Gemini Pro.
  // Instance ini dibuat static dan final agar hanya diinisialisasi sekali
  // dan dapat digunakan kembali di seluruh aplikasi.
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: _apiKey,
  );

  /// Mengambil pesan pengingat obat yang dihasilkan oleh model Gemini.
  ///
  /// Mengirim prompt ke Gemini API untuk menghasilkan pesan pengingat yang ramah.
  ///
  /// [medicineName] Nama obat yang akan diingatkan.
  /// [doseTime] Waktu minum obat (misal: "08:00 pagi" atau "21:30").
  ///
  /// Mengembalikan pesan pengingat yang dihasilkan oleh Gemini jika berhasil.
  /// Jika terjadi kesalahan (misalnya, masalah API, kunci tidak valid, dll.),
  /// akan mengembalikan pesan fallback yang sudah ditentukan.
  static Future<String> getReminderMessage(String medicineName, String doseTime) async {
    final prompt = '''
Buatkan pesan pengingat minum obat dengan nada ramah untuk obat $medicineName yang harus diminum pada pukul $doseTime. Gunakan bahasa Indonesia. Singkat dan jelas.
''';

    try {
      // Membuat objek Content dari prompt teks.
      // API Gemini menerima daftar Content sebagai input.
      final content = [Content.text(prompt)];

      // Mengirim permintaan ke model Gemini untuk menghasilkan konten.
      final response = await _model.generateContent(content);

      // Memeriksa dan mengekstrak teks dari respons Gemini.
      // Struktur respons dari SDK: response.candidates[0].content.parts[0].text
      if (response.candidates != null && response.candidates!.isNotEmpty) {
        final firstCandidate = response.candidates![0];
        if (firstCandidate.content != null && firstCandidate.content!.parts.isNotEmpty) {
          final firstPart = firstCandidate.content!.parts[0];
          if (firstPart is TextPart) {
            // Mengembalikan teks yang dihasilkan jika ditemukan dan berjenis teks.
            return firstPart.text;
          }
        }
      }

      // Fallback jika respons dari Gemini API tidak mengandung teks yang diharapkan
      print('DEBUG: Gemini API response did not contain expected text in a TextPart.');
      return 'Waktunya minum obat $medicineName!';

    } on GenerativeAIException catch (e) {
      // Menangani error spesifik yang mungkin berasal dari Google Generative AI API.
      // Contoh error: API Key tidak valid, model tidak ditemukan, kuota habis, masalah jaringan, dll.
      print('ERROR: Gemini API failed: ${e.message}');
      return 'Maaf, gagal membuat pesan pengingat. Jangan lupa minum obat $medicineName!';
    } catch (e) {
      // Menangani error umum lainnya yang mungkin terjadi di luar konteks API Gemini.
      print('ERROR: An unexpected error occurred with Gemini API: $e');
      return 'Ada masalah saat membuat pesan pengingat. Jangan lupa minum obat $medicineName!';
    }
  }
}