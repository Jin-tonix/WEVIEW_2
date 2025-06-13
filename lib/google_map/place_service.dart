import 'package:google_maps_webservice/places.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// PlaceSuggestionDTO 클래스 정의 (가정)
class PlaceSuggestionDTO {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  PlaceSuggestionDTO({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class PlaceService {
  // GoogleMapsPlaces 인스턴스를 lazy하게 초기화 (최초 1회만 생성)
  static final GoogleMapsPlaces _places = _initializePlaces();

  // Places 인스턴스 초기화
  static GoogleMapsPlaces _initializePlaces() {
    final apiKey = dotenv.env['GOOGLE_PLACES_ANDROID_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Places API key is not initialized!');
    }
    return GoogleMapsPlaces(apiKey: apiKey);
  }

  /// Place autocomplete
  Future<List<Prediction>> autocomplete(String input) async {
    try {
      final response = await _places.autocomplete(
        input,
        types: ['establishment'], // ex: 병원, 식당 등
        components: [Component(Component.country, 'KR')], // 국가 코드 'KR'
      );

      if (response.isOkay) {
        return response.predictions;
      } else {
        throw Exception('Failed to fetch predictions: ${response.errorMessage}');
      }
    } catch (e) {
      throw Exception('Autocomplete error: $e');
    }
  }

  /// Place detail lookup - This method is modified to return PlaceSuggestionDTO with latitude and longitude
  Future<PlaceSuggestionDTO> getPlaceDetail(String placeId) async {
    try {
      final response = await _places.getDetailsByPlaceId(placeId);

      if (response.isOkay) {
        final place = response.result;
        final latitude = place.geometry?.location.lat ?? 0.0;
        final longitude = place.geometry?.location.lng ?? 0.0;

        // Return PlaceSuggestionDTO with latitude and longitude
        return PlaceSuggestionDTO(
          name: place.name,
          address: place.formattedAddress ?? 'No address available',
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        throw Exception('Failed to fetch place details: ${response.errorMessage}');
      }
    } catch (e) {
      throw Exception('GetPlaceDetail error: $e');
    }
  }
}
