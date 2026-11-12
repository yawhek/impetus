import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:impetus/features/academy/models/academy_models.dart';
import 'package:impetus/features/academy/services/academy_service.dart';

class AcademyNotifier extends AsyncNotifier<List<SettoreFederale>> {
  @override
  Future<List<SettoreFederale>> build() async {
    ref.keepAlive(); // Mantieni il JSON in cache per evitare ricaricamenti
    return AcademyService.loadAcademyData();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(AcademyService.loadAcademyData);
  }
}

final academyDataProvider =
    AsyncNotifierProvider<AcademyNotifier, List<SettoreFederale>>(
        AcademyNotifier.new);
