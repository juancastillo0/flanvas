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
    return v.expand((e) => jsonEntries(e.value) ?? [(i++, e)]);
  }
  return null;
}
