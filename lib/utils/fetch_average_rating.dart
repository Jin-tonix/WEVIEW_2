import 'package:cloud_firestore/cloud_firestore.dart';

Future<double?> fetchAverageRatingFromFirestore(String placeId) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    double total = 0.0;
    int count = 0;

    for (var doc in querySnapshot.docs) {
      final rating = doc['rating'];
      if (rating != null && rating is num) {
        total += rating.toDouble();
        count++;
      }
    }

    if (count == 0) {
      return null;
    }

    return total / count;
  } catch (e) {
    print('❌ Error fetching average rating: $e');
    return null;
  }
}
