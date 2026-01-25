import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService._();

  // 🔑 REPLACE WITH YOUR GEMINI API KEY
  static const String _apiKey = 'AIzaSyCywglKgT3wRTk8g0znqcq5K2Tq6-mNVFI';

  static GenerativeModel? _model;
  static GenerativeModel? _imageModel;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );
    return _model!;
  }

  static GenerativeModel get imageModel {
    _imageModel ??= GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 1.0,
        topK: 40,
        topP: 0.95,
      ),
    );
    return _imageModel!;
  }

  /// Generate outfit combinations using Gemini AI
  static Future<List<Map<String, dynamic>>> generateOutfits({
    required List<Map<String, dynamic>> wardrobeItems,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      final prompt = _buildPrompt(wardrobeItems, userProfile);

      print('🤖 Calling Gemini AI...');
      print('📦 Wardrobe items: ${wardrobeItems.length}');

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Gemini returned empty response');
      }

      print('✅ Gemini response received');

      final outfits = _parseGeminiResponse(response.text!);

      print('✅ Parsed ${outfits.length} outfits');

      return outfits;
    } catch (e) {
      print('❌ Gemini error: $e');
      rethrow;
    }
  }

  /// Generate outfit image using Gemini
  static Future<String?> generateOutfitImage({
    required Map<String, dynamic> outfit,
    required Map<String, dynamic> wardrobeItems,
  }) async {
    try {
      print('🎨 Generating image for outfit: ${outfit['description']}');

      // Build description from actual wardrobe items
      final description = _buildImagePrompt(outfit, wardrobeItems);

      final prompt =
          '''
Generate a high-quality fashion photography image:

Subject: Professional fashion model
Outfit: $description
Style: Clean, modern, editorial fashion photography
Background: Off-white studio background
Lighting: Professional studio lighting, soft and even
Pose: Confident model pose, full body shot
Quality: High resolution, professional photography
Mood: Stylish, contemporary, aspirational

Create a photorealistic image of a fashion model wearing this exact outfit in a professional studio setting.
''';

      print('📸 Generating image...');

      final response = await imageModel.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        print('✅ Image generation response received');
        // Note: Gemini Flash doesn't directly return image URLs
        // We'll use a placeholder approach for now
        return 'GENERATED'; // Marker that image was "generated"
      }

      print('⚠️ No image generated');
      return null;
    } catch (e) {
      print('❌ Image generation error: $e');
      return null;
    }
  }

  /// Build image prompt from outfit data
  static String _buildImagePrompt(
    Map<String, dynamic> outfit,
    Map<String, dynamic> wardrobeItems,
  ) {
    final parts = <String>[];

    final items = outfit['items'] as Map<String, dynamic>;

    // Build description from item names
    if (items['tops'] != null) {
      final item = wardrobeItems[items['tops']];
      if (item != null) parts.add(item['name'] as String);
    }

    if (items['bottoms'] != null) {
      final item = wardrobeItems[items['bottoms']];
      if (item != null) parts.add(item['name'] as String);
    }

    if (items['dresses'] != null) {
      final item = wardrobeItems[items['dresses']];
      if (item != null) parts.add(item['name'] as String);
    }

    if (items['shoes'] != null) {
      final item = wardrobeItems[items['shoes']];
      if (item != null) parts.add(item['name'] as String);
    }

    if (items['accessories'] != null) {
      final item = wardrobeItems[items['accessories']];
      if (item != null) parts.add(item['name'] as String);
    }

    if (parts.isEmpty) {
      return outfit['description'] as String;
    }

    return parts.join(', ');
  }

  /// Build the prompt for Gemini
  static String _buildPrompt(
    List<Map<String, dynamic>> wardrobeItems,
    Map<String, dynamic> userProfile,
  ) {
    final stylePreferences = userProfile['stylePreferences'] as List<dynamic>?;
    final measurements = userProfile['measurements'] as Map<String, dynamic>?;
    final useCm = userProfile['useCm'] as bool? ?? true;

    final itemsByCategory = <String, List<Map<String, dynamic>>>{};
    for (final item in wardrobeItems) {
      final category = item['category'] as String;
      itemsByCategory.putIfAbsent(category, () => []);
      itemsByCategory[category]!.add(item);
    }

    final wardrobeDesc = StringBuffer();
    itemsByCategory.forEach((category, items) {
      wardrobeDesc.writeln('\n$category (${items.length} items):');
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        wardrobeDesc.writeln('  ${i + 1}. ${item['name']} (id: ${item['id']})');
      }
    });

    return '''
You are an expert fashion stylist AI. Create stylish outfit combinations from the user's wardrobe.

USER PROFILE:
${stylePreferences != null && stylePreferences.isNotEmpty ? '- Style Preferences: ${stylePreferences.join(", ")}' : '- Style Preferences: Not specified'}
${measurements != null ? '''- Measurements (${useCm ? 'cm' : 'inches'}):
  - Chest: ${measurements['chest']}
  - Waist: ${measurements['waist']}
  - Shoulder: ${measurements['shoulder']}
  - Height: ${measurements['height']}''' : '- Measurements: Not provided'}

WARDROBE:$wardrobeDesc

TASK:
Create 10-15 creative outfit combinations. Be smart and dynamic:

RULES:
1. **No fixed formulas** - Don't always use "1 top + 1 bottom + 1 shoes"
2. **Be flexible**:
   - If there's a dress, it can be a complete outfit (dress + shoes + accessory)
   - Casual outfits might be: top + bottom + shoes
   - Formal outfits might be: top + bottom + shoes + accessories
   - Party outfits might be: dress + heels + clutch
3. **Categories to use**:
   - casual: Relaxed, everyday wear
   - business_casual: Office-appropriate but relaxed
   - formal: Professional, elegant
   - party: Fun, stylish, event-ready
   - streetwear: Urban, trendy
   - athletic: Gym, sports activities
4. **Consider the user's style preferences** when choosing combinations
5. **Be creative and descriptive** - make descriptions exciting and specific
6. **Explain WHY outfits work** - mention colors, fit, occasion

OUTPUT FORMAT (JSON only, no markdown):
[
  {
    "items": {
      "tops": "item_id_here or null",
      "bottoms": "item_id_here or null",
      "shoes": "item_id_here or null",
      "accessories": "item_id_here or null",
      "dresses": "item_id_here or null"
    },
    "category": "casual",
    "description": "Effortlessly cool weekend look pairing your blue denim shirt with black chinos. The relaxed fit of the shirt balances perfectly with the tailored pants, while white sneakers keep it casual and comfortable. Perfect for coffee runs or casual meetups.",
    "tags": ["blue", "casual", "comfortable", "weekend"]
  }
]

Return ONLY the JSON array, nothing else. No markdown, no explanations.
''';
  }

  /// Parse Gemini's JSON response
  static List<Map<String, dynamic>> _parseGeminiResponse(String responseText) {
    try {
      String cleaned = responseText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final List<dynamic> outfits = jsonDecode(cleaned);

      return outfits.map((outfit) {
        return {
          'items': outfit['items'] as Map<String, dynamic>,
          'category': outfit['category'] as String,
          'description': outfit['description'] as String,
          'tags': List<String>.from(outfit['tags'] ?? []),
        };
      }).toList();
    } catch (e) {
      print('❌ JSON parse error: $e');
      print('Response text: $responseText');
      throw Exception('Failed to parse Gemini response: $e');
    }
  }
}
