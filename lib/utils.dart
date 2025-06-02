bool jsonEqual(Object? a, Object? b) {
  if (a == b) {
    return true;
  } else if (a is Map && b is Map) {
    return a.length == b.length &&
        a.entries.every(
          (e) => b.containsKey(e.key) && jsonEqual(e.value, b[e.key]),
        );
  } else if (a is List && b is List) {
    int i = 0;
    return a.length == b.length && a.every((e) => jsonEqual(e, b[i++]));
  }
  return false;
}

Iterable<(Object?, Object?)>? jsonEntries(Object? v) {
  if (v is Map) {
    return v.entries.expand((e) => jsonEntries(e.value) ?? [(e.key, e.value)]);
  } else if (v is List) {
    int i = 0;
    return v.expand((e) => jsonEntries(e) ?? [(i++, e)]);
  }
  return null;
}

extension DoubleRound on double {
  String get str {
    final i = toInt();
    if (i == this) return i.toString();
    if (equalDouble(roundPrecision(1))) return toStringAsFixed(1);
    final p = toStringAsPrecision(1);
    return p.contains('e') ? toString() : p;
  }

  double roundPrecision(int precision) {
    final m = 10 * precision;
    return (this * m).roundToDouble() / m;
  }

  bool equalDouble(double other) => (this - other).abs() < 0.000001;
}
