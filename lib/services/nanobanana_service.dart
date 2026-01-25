import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NanoBananaService {
  NanoBananaService._();

  static const String _projectId = 'wardrobeai-ba408';
  static const String _location = 'us-central1';
  static const int maxImagesPerRun = 3; // ✅ NO LIMIT - Generate ALL images

  static ServiceAccountCredentials? _credentials;
  static AccessCredentials? _accessCredentials;

  static Future<void> _initializeCredentials() async {
    if (_credentials != null && _accessCredentials != null) return;

    try {
      final jsonString = await rootBundle.loadString(
        'lib/config/service-account.json',
      );
      final jsonData = jsonDecode(jsonString);

      _credentials = ServiceAccountCredentials.fromJson(jsonData);

      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      final client = http.Client();

      _accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        _credentials!,
        scopes,
        client,
      );

      print('✅ Vertex AI credentials initialized');
    } catch (e) {
      print('❌ Failed to initialize credentials: $e');
      rethrow;
    }
  }

  static Future<String?> generateTryOnImage({
    required String frontBodyImageUrl,
    required String sideBodyImageUrl,
    required String backBodyImageUrl,
    required List<String> clothingImageUrls,
    required String description,
    required String gender,
  }) async {
    try {
      await _initializeCredentials();

      if (_accessCredentials == null) {
        print('❌ No access credentials');
        return null;
      }

      print('🎨 Generating outfit image with Imagen 3...');

      final prompt =
          '''
Professional fashion photography of a $gender model wearing: $description

Style: Clean, modern editorial fashion photography
Background: Off-white studio background, minimalist
Lighting: Professional studio lighting
Pose: Confident full-body standing pose
Model: Attractive $gender fashion model
Quality: High resolution, photorealistic
Aesthetic: Contemporary fashion magazine style

Full body fashion photograph.
''';

      final url = Uri.parse(
        'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/imagen-3.0-generate-001:predict',
      );

      final accessToken = _accessCredentials!.accessToken.data;

      print('📡 Calling Vertex AI Imagen 3...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'instances': [
            {'prompt': prompt},
          ],
          'parameters': {'sampleCount': 1, 'aspectRatio': '3:4'},
        }),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          final prediction = data['predictions'][0];

          if (prediction['bytesBase64Encoded'] != null) {
            final imageBase64 = prediction['bytesBase64Encoded'];
            print('✅ Image generated successfully');
            return 'data:image/png;base64,$imageBase64';
          }
        }
      } else {
        print('❌ Imagen failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }

      return null;
    } catch (e) {
      print('❌ Imagen error: $e');
      return null;
    }
  }

  static String _buildPrompt(String description, String gender) {
    return description;
  }
}
