import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_edit.dart'; // 글 수정 페이지
import 'comment_section.dart';

class CommunityDetailPage extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  const CommunityDetailPage({super.key, required this.postId, required this.post});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          // 작성자 본인만 수정/삭제 버튼 보이기
          if (post['uid'] == user?.uid) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: () async {
                // 글 수정 페이지로 이동
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityEditPage(postId: postId, post: post),
                  ),
                );
                // 수정 후 새로고침이 필요하면 setState가 가능한 방식으로 바꿔주세요
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('글 삭제'),
                    content: const Text('정말 삭제하시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                  if (context.mounted) {
                    Navigator.pop(context); // 삭제 후 목록으로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('삭제되었습니다')),
                    );
                  }
                }
              },
            ),
          ]
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Text(
                post['category'] ?? '',
                style: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              post['title'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32, color: Colors.indigo),
            Text(
              post['content'] ?? '',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(child: CommentSection(postId: postId)),
          ],
        ),
      ),
    );
  }
}
