import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:impetus/features/academy/models/academy_models.dart';

// Parsing JSON in isolate separato per evitare cali di frame sul main thread.
List<SettoreFederale> _parseAcademyData(String jsonString) {
  final data = jsonDecode(jsonString) as List<dynamic>;
  return data
      .map((e) => SettoreFederale.fromJson(e as Map<String, dynamic>))
      .toList();
}

class AcademyService {
  static Future<List<SettoreFederale>> loadAcademyData() async {
    final jsonString =
        await rootBundle.loadString('assets/data/academy_data.json');
    return compute(_parseAcademyData, jsonString);
  }
}
