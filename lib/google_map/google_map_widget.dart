import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place.dart';

class GoogleMapWidget extends StatefulWidget {
  final Place? selectedPlace;
  final Function(String placeId, String name) onMarkerTap;

  const GoogleMapWidget({
    super.key,
    required this.selectedPlace,
    required this.onMarkerTap,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedPlace;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: selected != null
            ? LatLng(selected.latitude, selected.longitude)  // 마커의 위치
            : const LatLng(37.5665, 126.9780), // 서울 기본 위치
        zoom: 14,
      ),
      markers: selected != null
          ? {
        Marker(
          markerId: MarkerId(selected.placeId),
          position: LatLng(selected.latitude, selected.longitude),  // 마커 위치 좌표
          infoWindow: InfoWindow(
            title: selected.name,
            snippet: selected.address,
            onTap: () {
              widget.onMarkerTap(
                selected.placeId,
                selected.name,
              );
            },
          ),
        ),
      }
          : {},
    );
  }
}

