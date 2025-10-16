import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class FirebaseAiService {
  FirebaseAiService({GenerativeModel? model, String? modelName})
    : _model =
          model ??
          FirebaseAI.googleAI().generativeModel(
            model: modelName ?? 'gemini-2.5-flash',
          );

  final GenerativeModel _model;

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

  Future<Map<String, dynamic>> imageToDishcovery({
    required Uint8List imageBytes,
    String prompt = '',
    String languageCode = 'id',
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
        responseSchema: _dishcoverySchema(languageCode),
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

  Stream<Map<String, dynamic>> imageToDishcoveryStream({
    required Uint8List imageBytes,
    String prompt = '',
    String languageCode = 'id',
  }) async* {
    final parts = <Part>[];
    if (prompt.trim().isNotEmpty) {
      parts.add(TextPart(prompt));
    }
    parts.add(InlineDataPart('image/jpeg', imageBytes));

    final stream = _model.generateContentStream(
      [Content.multi(parts)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _dishcoverySchema(languageCode),
      ),
    );

    String accumulatedText = '';

    await for (final response in stream) {
      if (response.text != null && response.text!.isNotEmpty) {
        accumulatedText += response.text!;

        try {
          final decoded = json.decode(accumulatedText);
          if (decoded is Map<String, dynamic>) {
            yield decoded;
          }
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
        }
      }
    }

    if (accumulatedText.isNotEmpty) {
      try {
        final decoded = json.decode(accumulatedText);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      } catch (e) {
        throw FirebaseAIException('Failed to parse final JSON: $e');
      }
    }
  }

  Future<Uint8List> readImageFile(String path) async {
    final f = File(path);
    if (!await f.exists()) {
      throw FirebaseAIException('Image not found');
    }
    return await f.readAsBytes();
  }

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

  Schema _dishcoverySchema([String languageCode = 'id']) {
    final isIndonesian = languageCode == 'id';

    return Schema.object(
      properties: {
        'name': Schema.string(
          description: isIndonesian
              ? "Nama makanan dalam Bahasa Indonesia."
              : "Food name in English.",
        ),
        'origin': Schema.string(
          description: isIndonesian
              ? "Daerah asal makanan, dengan format 'Nama Kota, Nama Provinsi' - contoh: 'Bandung, Jawa Barat'."
              : "Origin of the food, with format 'City Name, Province Name' - example: 'Bandung, West Java'.",
        ),
        'description': Schema.string(
          description: isIndonesian
              ? "Deskripsi singkat dan menarik tentang makanan dalam format Markdown."
              : "Brief and interesting description about the food in Markdown format.",
        ),
        'isFood': Schema.boolean(
          description: isIndonesian
              ? "Apakah ini adalah makanan?"
              : "Is this food?",
        ),
        'history': Schema.string(
          description: isIndonesian
              ? "Cerita atau sejarah singkat atau fakta unik di balik makanan dalam format Markdown."
              : "Brief story or history or unique facts behind the food in Markdown format.",
        ),
        'recipe': Schema.object(
          properties: {
            'ingredients': Schema.array(
              items: Schema.string(),
              description: isIndonesian
                  ? "Daftar bahan-bahan yang dibutuhkan."
                  : "List of required ingredients.",
            ),
            'steps': Schema.array(
              items: Schema.string(),
              description: isIndonesian
                  ? "Langkah-langkah memasak."
                  : "Cooking steps.",
            ),
          },
        ),
        'tags': Schema.array(
          items: Schema.string(),
          description: isIndonesian
              ? "Tag - tag untuk pengkategorian makanan."
              : "Tags for food categorization.",
        ),
      },
    );
  }
}
