import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

class FirebaseAiService {
  FirebaseAiService({GenerativeModel? model})
    : _model =
          model ??
          FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  final GenerativeModel _model;

  /// Convert image to plain text description
  Future<String> imageToText({
    required Uint8List imageBytes,
    String prompt = '',
  }) async {
    final parts = <Part>[];
    if (prompt.trim().isNotEmpty) {
      parts.add(TextPart(prompt));
    }
    parts.add(InlineDataPart('image/jpeg', imageBytes));

    final res = await _model.generateContent([Content.multi(parts)]);
    if (res.text == null || res.text!.isEmpty) {
      throw FirebaseAIException('Empty response');
    }
    return res.text!;
  }

  /// Convert image to structured data (generic schema)
  Future<Map<String, dynamic>> imageToStructured({
    required Uint8List imageBytes,
    String prompt = '',
  }) async {
    final parts = <Part>[];
    if (prompt.trim().isNotEmpty) {
      parts.add(TextPart(prompt));
    }
    parts.add(InlineDataPart('image/jpeg', imageBytes));

    final res = await _model.generateContent(
      [Content.multi(parts)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _defaultImageSchema(),
      ),
    );

    final text = res.text;
    if (text == null || text.isEmpty) {
      throw FirebaseAIException('Empty response');
    }

    final decoded = json.decode(text);
    if (decoded is! Map<String, dynamic>) {
      throw FirebaseAIException('Non-object JSON returned');
    }
    return decoded;
  }

  /// Convert text to structured JSON
  Future<Map<String, dynamic>> textToStructured({
    required String prompt,
  }) async {
    final res = await _model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _defaultTextSchema(),
      ),
    );

    final text = res.text;
    if (text == null || text.isEmpty) {
      throw FirebaseAIException('Empty response');
    }

    final decoded = json.decode(text);
    if (decoded is! Map<String, dynamic>) {
      throw FirebaseAIException('Non-object JSON returned');
    }
    return decoded;
  }

  /// Convert image to Dishcovery structured schema
  Future<Map<String, dynamic>> imageToDishcovery({
    required Uint8List imageBytes,
    String prompt = '',
  }) async {
    final parts = <Part>[];
    if (prompt.trim().isNotEmpty) {
      parts.add(TextPart(prompt));
    }
    parts.add(InlineDataPart('image/jpeg', imageBytes));

    final res = await _model.generateContent(
      [Content.multi(parts)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _dishcoverySchema(),
      ),
    );

    final text = res.text;
    if (text == null || text.isEmpty) {
      throw FirebaseAIException('Empty response');
    }

    final decoded = json.decode(text);
    if (decoded is! Map<String, dynamic>) {
      throw FirebaseAIException('Non-object JSON returned');
    }
    return decoded;
  }

  /// Read image from file path into bytes
  Future<Uint8List> readImageFile(String path) async {
    final f = File(path);
    if (!await f.exists()) {
      throw FirebaseAIException('Image not found');
    }
    return await f.readAsBytes();
  }

  // Default schemas
  Schema _defaultImageSchema() {
    return Schema.object(
      properties: {
        'summary': Schema.string(),
        'objects': Schema.array(
          items: Schema.object(
            properties: {
              'label': Schema.string(),
              'confidence': Schema.number(),
            },
          ),
        ),
      },
      optionalProperties: ['objects'],
    );
  }

  Schema _defaultTextSchema() {
    return Schema.object(
      properties: {'keyPoints': Schema.array(items: Schema.string())},
    );
  }

  Schema _dishcoverySchema() {
    return Schema.object(
      properties: {
        'name': Schema.string(
          description: "Nama makanan dalam Bahasa Indonesia.",
        ),
        'origin': Schema.string(
          description: "Daerah asal makanan, contoh: 'Bandung, Jawa Barat'.",
        ),
        'description': Schema.string(
          description:
              "Deskripsi singkat dan menarik tentang makanan dalam format Markdown.",
        ),
        'history': Schema.string(
          description:
              "Cerita atau sejarah singkat di balik makanan dalam format Markdown.",
        ), // <-- FIELD BARU
        'recipe': Schema.object(
          // <-- OBJEK BARU
          properties: {
            'ingredients': Schema.array(
              items: Schema.string(),
              description: "Daftar bahan-bahan yang dibutuhkan.",
            ),
            'steps': Schema.array(
              items: Schema.string(),
              description: "Langkah-langkah memasak.",
            ),
          },
        ),
        'tags': Schema.array(items: Schema.string()),
        'relatedFoods': Schema.array(items: Schema.string()),
      },
    );
  }
}
