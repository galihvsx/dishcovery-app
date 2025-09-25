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
}
