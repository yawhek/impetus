import 'dart:math' as math;

class LowPassFilter {
  LowPassFilter(this.alpha, [this.s = 0.0]);

  double alpha;
  double s;
  bool _initialized = false;

  double filter(double value) {
    if (!_initialized) {
      s = value;
      _initialized = true;
      return value;
    }
    return s = (alpha * value) + ((1.0 - alpha) * s);
  }

  double filterWithAlpha(double value, double customAlpha) {
    alpha = customAlpha;
    return filter(value);
  }

  bool get isInitialized => _initialized;

  void reset() {
    _initialized = false;
    s = 0.0;
  }
}

// One Euro Filter (Casiez et al., 2012): riduce il tremolio a riposo senza ritardare i colpi veloci
class OneEuroFilter {
  OneEuroFilter({
    this.minCutoff = 1.0,
    this.beta = 0.08,
    this.dCutoff = 1.0,
  })  : _xFilter = LowPassFilter(1),
        _dxFilter = LowPassFilter(1);

  final double minCutoff;
  final double beta;
  final double dCutoff;

  final LowPassFilter _xFilter;
  final LowPassFilter _dxFilter;

  double? _lastTime;
  double? _prevRawValue;

  double filter(double value, [double? timestampSeconds]) {
    if (!value.isFinite) {
      return _xFilter.isInitialized ? _xFilter.s : 0.0;
    }

    final now = timestampSeconds ??
        (DateTime.now().microsecondsSinceEpoch / 1000000.0);

    if (_lastTime == null) {
      _lastTime = now;
      _prevRawValue = value;
      return _xFilter.filter(value);
    }

    final dt = now - _lastTime!;
    if (dt > 0.5) {
      // Occlusione prolungata: azzero lo stato per evitare picchi di derivata alla ripresa
      reset();
      _lastTime = now;
      _prevRawValue = value;
      return _xFilter.filter(value);
    }
    if (dt <= 0.0) {
      return _xFilter.isInitialized ? _xFilter.s : value;
    }
    _lastTime = now;

    final dx = (value - (_prevRawValue ?? value)) / dt;
    _prevRawValue = value;
    final edx = _dxFilter.filterWithAlpha(dx, _calculateAlpha(dt, dCutoff));

    final cutoff = minCutoff + (beta * edx.abs());

    return _xFilter.filterWithAlpha(value, _calculateAlpha(dt, cutoff));
  }

  double _calculateAlpha(double dt, double cutoff) {
    final tau = 1.0 / (2.0 * math.pi * cutoff);
    return 1.0 / (1.0 + (tau / dt));
  }

  void reset() {
    _xFilter.reset();
    _dxFilter.reset();
    _lastTime = null;
    _prevRawValue = null;
  }
}
