import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:impetus/core/math/one_euro_filter.dart';

double _rms(List<double> values) {
  final sumSq = values.fold<double>(0, (acc, v) => acc + v * v);
  return math.sqrt(sumSq / values.length);
}

void main() {
  group('OneEuroFilter', () {
    test('abatte sensibilmente il jitter RMS a riposo rispetto al segnale raw',
        () {
      final filter = OneEuroFilter();
      final rawOffsets = <double>[];
      final filteredOffsets = <double>[];

      // Simulazione di jitter pseudo-casuale/sinusoidale attorno a 100.0 px a 30 Hz
      const double baseline = 100;
      for (var i = 0; i < 120; i++) {
        final t = i / 30.0;
        final noise = 4.5 * math.sin(i * 1.9) + 2.2 * math.cos(i * 3.7);
        final raw = baseline + noise;
        final smoothed = filter.filter(raw, t);
        if (i >= 15) {
          rawOffsets.add(raw - baseline);
          filteredOffsets.add(smoothed - baseline);
        }
      }

      final rawRms = _rms(rawOffsets);
      final filteredRms = _rms(filteredOffsets);

      expect(filteredRms, lessThan(rawRms * 0.45));
    });

    test('segue rapidamente un cambio di posizione veloce (basso lag)', () {
      final filter = OneEuroFilter(beta: 0.12);
      var t = 0.0;
      for (var i = 0; i < 15; i++) {
        filter.filter(100, t);
        t += 1 / 30.0;
      }

      // Movimento rapido di 200 px in 5 frame (166 ms)
      double output = 100;
      for (var i = 1; i <= 5; i++) {
        output = filter.filter(100 + i * 40, t);
        t += 1 / 30.0;
      }

      expect(output, greaterThan(255));
    });

  });
}
