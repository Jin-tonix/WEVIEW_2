import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_detail_screen.dart'; // ReviewDetailScreen 페이지 추가

class ReviewList extends StatelessWidget {
  final String placeId;

  const ReviewList({super.key, required this.placeId});

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    try {
      print("Fetching reviews for placeId: $placeId");

      final reviewSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .get();

      List<Map<String, dynamic>> reviews = reviewSnap.docs.map((d) => d.data()).toList();

      reviews.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
      reviews.sort((a, b) => (b['comment']?.length ?? 0).compareTo(a['comment']?.length ?? 0));

      print("Fetched ${reviews.length} reviews.");
      return reviews;
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),  // 뒤로 가기
        ),
        title: const Text("Reviews"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reviews available.'));
          }

          final reviews = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 5,
                child: InkWell(
                  onTap: () {
                    // 리뷰를 눌렀을 때 ReviewDetailScreen으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewDetailScreen(review: review),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['comment'] ?? 'No comment',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${review['rating'] ?? 0}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
