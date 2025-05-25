import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final String _apiKey = dotenv.env['API_KEY']!;
  static const String _apiUrl =
      'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0';

  Future<Uint8List> generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'height': 512,
            'width': 512,
            'num_inference_steps': 25,
          },
        }),
      );

      print('API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 30));
        return generateImage(prompt);
      }

      throw Exception('${response.statusCode}: ${response.body}');
    } catch (e) {
      throw Exception('API Error: ${e.toString()}');
    }
  }
}
