import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'hospital_detail_screen.dart';
import 'recommendation_card.dart';
import '../google_map/place.dart';
import '../utils/json_parser.dart';

class HospitalSearchScreen extends StatefulWidget {
  final String? initialKeyword;
  const HospitalSearchScreen({super.key, this.initialKeyword});

  @override
  State<HospitalSearchScreen> createState() => _HospitalSearchScreenState();
}

class _HospitalSearchScreenState extends State<HospitalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapsPlaces? _places;
  List<Place> hospitals = [];
  Set<Marker> _markers = {};
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 13,
  );
  GoogleMapController? _mapController;
  bool _isLoading = false;
  late String apiKey;
  List<Place> recommendedPlaces = [];

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['GOOGLE_PLACES_ANDROID_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('❌ GOOGLE_PLACES_ANDROID_API_KEY not found!');
    } else {
      _places = GoogleMapsPlaces(apiKey: apiKey);
    }
    requestLocationPermission();

    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchController.text = widget.initialKeyword!;
        searchHospitals();
      });
    }
  }

  // Method to build the photo URL
  String buildPhotoUrl(String photoReference, String apiKey) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
  }

  Future<void> requestLocationPermission() async {
    try {
      var locationServiceEnabled = await loc.Location().serviceEnabled();
      if (!locationServiceEnabled) {
        locationServiceEnabled = await loc.Location().requestService();
      }

      if (!locationServiceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permissionStatus = await loc.Location().hasPermission();
      if (permissionStatus == loc.PermissionStatus.denied) {
        permissionStatus = await loc.Location().requestPermission();
      }

      if (permissionStatus != loc.PermissionStatus.granted) {
        throw Exception('Location permission not granted.');
      }

      var currentLocation = await loc.Location().getLocation();
      setState(() {
        _initialPosition = CameraPosition(
          target: LatLng(
            currentLocation.latitude ?? 0.0,
            currentLocation.longitude ?? 0.0,
          ),
          zoom: 14,
        );
      });
    } catch (e) {
      debugPrint("❌ Failed to get location or permission: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Failed to get location or permission")),
      );
    }
  }

  Future<String> classifyQuery(String query) async {
    final uri = Uri.parse("http://10.0.2.2:8000/classify-query");

    try {
      loc.Location location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          throw Exception('Location permission not granted.');
        }
      }

      var currentLocation = await location.getLocation();

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "location": {
            "latitude": currentLocation.latitude ?? 0.0,
            "longitude": currentLocation.longitude ?? 0.0
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["classification"];
      } else {
        debugPrint('❌ Error: ${response.statusCode}');
        throw Exception('Failed to classify query');
      }
    } catch (e) {
      debugPrint('❌ Classification error: $e');
      throw Exception("Error classifying query");
    }
  }

  Future<List<Place>> sendToLLM(String query, Map<String, double> location) async {
    final uri = Uri.parse("http://10.0.2.2:8000/suggest-places");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"query": query, "location": location}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List suggestions = data["suggestedPlaces"];

        return suggestions.map<Place>((item) {
          return Place.fromLLMJson({
            'name': item["name"] ?? "",
            'address': item["address"] ?? "No address available",
            'reason': item["reason"] ?? "",
          });
        }).toList();
      } else {
        throw Exception("Failed to fetch recommendation");
      }
    } catch (e) {
      debugPrint("❌ Error fetching data: $e");
      throw Exception("Failed to connect to the server");
    }
  }

  Future<void> onCardTap(Place place) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalDetailScreen(place: place),
      ),
    );
  }

  Future<void> searchHospitals() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      hospitals = [];
      _markers = {};
      recommendedPlaces = [];
    });

    try {
      final classification = await classifyQuery(keyword);

      if (classification == 'recommendation') {
        final locData = await loc.Location().getLocation();

        final location = <String, double>{
          "latitude": locData.latitude ?? 0.0,
          "longitude": locData.longitude ?? 0.0,
        };

        final suggestions = await sendToLLM(keyword, location);
        setState(() {
          recommendedPlaces = suggestions.take(3).toList();
          _markers = recommendedPlaces.map((place) {
            return Marker(
              markerId: MarkerId(place.name),
              position: LatLng(place.latitude, place.longitude),
              infoWindow: InfoWindow(title: place.name, snippet: place.address),
              onTap: () => onCardTap(place),
            );
          }).toSet();
          _isLoading = false;
        });
      } else if (classification == 'location') {
        if (_places == null) {
          debugPrint("❌ GoogleMapsPlaces not initialized");
          return;
        }

        final placesSearchResults = await _places!.searchByText(keyword);

        if (!placesSearchResults.isOkay || placesSearchResults.results.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }

        List<Map<String, dynamic>> rawPlaces = [];
        Set<Marker> tempMarkers = {};

        for (var p in placesSearchResults.results) {
          final placeId = p.placeId;
          final detail = await _places!.getDetailsByPlaceId(placeId);
          if (!detail.isOkay || detail.result.geometry?.location == null) continue;

          final r = detail.result;
          final mapData = {
            'place_id': r.placeId,
            'name': r.name,
            'formatted_address': r.formattedAddress ?? '',
            'geometry': {
              'location': {
                'lat': r.geometry!.location.lat.toDouble(),
                'lng': r.geometry!.location.lng.toDouble(),
              }
            },
            'formatted_phone_number': r.formattedPhoneNumber ?? '',
            'rating': r.rating?.toDouble() ?? 0.0,
            'photoUrl': (r.photos != null && r.photos.isNotEmpty)
                ? buildPhotoUrl(r.photos.first.photoReference, apiKey)
                : null,
          };

          rawPlaces.add(mapData);

          tempMarkers.add(Marker(
            markerId: MarkerId(r.placeId),
            position: LatLng(r.geometry!.location.lat, r.geometry!.location.lng),
            infoWindow: InfoWindow(title: r.name, snippet: r.formattedAddress),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HospitalDetailScreen(place: Place.fromJson(mapData)),
                ),
              );
            },
          ));
        }

        final parsedPlaces = await parsePlacesInBackground(rawPlaces);

        setState(() {
          hospitals = parsedPlaces;
          _markers = tempMarkers;
          _isLoading = false;

          if (parsedPlaces.isNotEmpty) {
            final first = parsedPlaces[0];
            _initialPosition = CameraPosition(
              target: LatLng(first.latitude, first.longitude),
              zoom: 15,
            );
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(first.latitude, first.longitude),
                16,
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,  // 마커가 여기서 제대로 표시되는지 확인
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Material(
              elevation: 3,
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Enter hospital or keyword",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          _searchController.text = value;
                          searchHospitals();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: searchHospitals,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (recommendedPlaces.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedPlaces.length,
                itemBuilder: (context, idx) {
                  final place = recommendedPlaces[idx];
                  return Container(
                    width: 250,
                    padding: const EdgeInsets.all(8),
                    child: RecommendationCard(
                      title: place.name,
                      reason: place.reason ?? '',
                      address: place.address,
                      onTap: () => onCardTap(place),
                    ),
                  );
                },
              ),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
