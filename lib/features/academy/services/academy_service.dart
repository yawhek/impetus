import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:impetus/features/academy/models/academy_models.dart';

class AcademyService {
  static Future<List<SettoreFederale>> loadAcademyData() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/academy_data.json');
      final data = jsonDecode(jsonString) as List<dynamic>;
      return data
          .map((e) => SettoreFederale.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Errore nel caricamento dei dati accademia: $e');
      return [];
    }
  }
}
