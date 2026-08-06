import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenFDARepository {
  static const String _url = 'https://api.fda.gov/drug/event.json?limit=100';

  Future<List<dynamic>> fetchEvents() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode == 200) {
      // Offload JSON parsing to a background isolate using compute()
      // This ensures the main thread stays free for 60/120 FPS rendering.
      return await compute(_parseJson, response.body);
    } else {
      throw Exception('Failed to load FDA events (Status: ${response.statusCode})');
    }
  }

  // This function runs in a separate isolate
  static List<dynamic> _parseJson(String responseBody) {
    // Timeline event helps verify Isolate execution in DevTools
    Timeline.startSync('OpenFDA_JSON_Parse');
    try {
      final Map<String, dynamic> parsed = jsonDecode(responseBody);
      return parsed['results'] as List<dynamic>;
    } finally {
      Timeline.finishSync();
    }
  }
}
