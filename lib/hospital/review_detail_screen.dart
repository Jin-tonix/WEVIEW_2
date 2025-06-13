import 'package:flutter/material.dart';

class ReviewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewDetailScreen({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Detail"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // 뒤로 가기
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TextStyle을 직접 설정
            Text(
              'Comment:',
              style: TextStyle(
                fontSize: 22,  // 원하는 폰트 크기 설정
                fontWeight: FontWeight.bold,
                color: Colors.black,  // 원하는 색상 설정
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review['comment'] ?? 'No comment',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // 별점
            Text(
              'Rating: ${review['rating'] ?? 0}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 추가 정보(예시: 작성자 등)
            Text(
              'Reviewer: ${review['reviewerName'] ?? 'Anonymous'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
