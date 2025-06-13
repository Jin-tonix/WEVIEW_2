import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../google_map/place.dart';

List<Place> parsePlaces(String rawList) {
  final List<dynamic> decoded = json.decode(rawList);
  return decoded.map((e) => Place.fromJson(e)).toList();
}

Future<List<Place>> parsePlacesInBackground(List<Map<String, dynamic>> data) async {
  final jsonStr = json.encode(data);
  return compute(parsePlaces, jsonStr);
}
