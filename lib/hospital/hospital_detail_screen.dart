import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../google_map/place.dart';
import 'review_list.dart';
import '../utils/fetch_average_rating.dart';  // ✅ 평점 가져오기 함수 import

class HospitalDetailScreen extends StatefulWidget {
  final Place place;

  const HospitalDetailScreen({super.key, required this.place});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  double? firestoreRating;
  bool isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    loadFirestoreRating();
  }

  Future<void> loadFirestoreRating() async {
    final avgRating = await fetchAverageRatingFromFirestore(widget.place.placeId);
    setState(() {
      firestoreRating = avgRating;
      isLoadingRating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final hasLocation = place.latitude != 0.0 && place.longitude != 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: Stack(
        children: [
          if (hasLocation)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(place.latitude, place.longitude),
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('hospitalMarker'),
                  position: LatLng(place.latitude, place.longitude),
                ),
              },
              myLocationEnabled: false,
              zoomControlsEnabled: false,
            )
          else
            const Center(
              child: Text(
                'No location information available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewList(placeId: place.placeId),
                  ),
                );
              },
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (place.photoUrl != null && place.photoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: place.photoUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const LinearProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.address,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      if ((place.description ?? '').isNotEmpty)
                        Text(
                          '"${place.description}"',
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 6),
                      if (place.phoneNumber != null && place.phoneNumber!.isNotEmpty)
                        Text(
                          'Phone: ${place.phoneNumber}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 6),
                      if (place.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${place.rating}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      if (isLoadingRating)
                        const Text(
                          'Loading user reviews...',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        )
                      else if (firestoreRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star_rate_rounded, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'User Reviews: ${firestoreRating!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'User Reviews: No reviews yet',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
