import 'package:flutter_dotenv/flutter_dotenv.dart';

class Place {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? photoReference;
  final String? website;
  final double? rating;
  final String? photoUrl;
  final String? reason;
  final String? description;  // ✅ 추가

  Place({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.photoReference,
    this.website,
    this.rating,
    this.photoUrl,
    this.reason,
    this.description,  // ✅ 추가
  });

  // Factory for Google Places API response
  factory Place.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']?['location'] ?? {};
    final lat = (location['lat'] is num) ? (location['lat'] as num).toDouble() : 0.0;
    final lng = (location['lng'] is num) ? (location['lng'] as num).toDouble() : 0.0;

    // photo_reference
    final photoRef = (json['photos'] != null &&
        json['photos'] is List &&
        (json['photos'] as List).isNotEmpty)
        ? (json['photos'][0]['photo_reference'] as String?)
        : null;

    // API key
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

    // photoUrl
    final photoUrl = (photoRef != null && photoRef.isNotEmpty)
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoRef&key=$apiKey'
        : null;

    // rating
    final rating = (json['rating'] is num)
        ? (json['rating'] as num).toDouble()
        : double.tryParse(json['rating']?.toString() ?? '');

    return Place(
      placeId: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['formatted_address']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      phoneNumber: json['formatted_phone_number']?.toString(),
      photoReference: photoRef,
      website: json['website']?.toString(),
      rating: rating,
      photoUrl: photoUrl,
      reason: json['reason']?.toString(),
      description: json['description']?.toString(),  // ✅ 추가
    );
  }

  // Factory for LLM response
  factory Place.fromLLMJson(Map<String, dynamic> json) {
    return Place(
      placeId: '', // No placeId from LLM
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: 0.0,
      longitude: 0.0,
      phoneNumber: null,
      photoReference: null,
      website: null,
      rating: null,
      photoUrl: null,
      reason: json['reason']?.toString(),
      description: json['description']?.toString(),  // ✅ 추가
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'photoReference': photoReference,
      'website': website,
      'rating': rating,
      'photoUrl': photoUrl,
      'reason': reason,
      'description': description,  // ✅ 추가
    };
  }
}
