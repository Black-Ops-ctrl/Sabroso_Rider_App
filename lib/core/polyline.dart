class LatLngPoint {
  const LatLngPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

List<LatLngPoint> decodePolyline(String? encoded) {
  final out = <LatLngPoint>[];
  if (encoded == null || encoded.isEmpty) return out;
  var index = 0;
  var lat = 0;
  var lng = 0;
  final len = encoded.length;
  try {
    while (index < len) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      if (index >= len) break;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      out.add(LatLngPoint(lat / 1e5, lng / 1e5));
    }
  } catch (_) {}
  return out;
}
