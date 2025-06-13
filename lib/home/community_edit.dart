import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityEditPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;
  const CommunityEditPage({super.key, required this.postId, required this.post});

  @override
  State<CommunityEditPage> createState() => _CommunityEditPageState();
}

class _CommunityEditPageState extends State<CommunityEditPage> {
  late String selectedCategory;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final List<String> categories = [
    '병원', '카페', '약국', '음식점', '관광명소', '문화시설', '숙박', '지하철역', '편의점'
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.post['category'] ?? categories[0];
    _titleController = TextEditingController(text: widget.post['title'] ?? '');
    _contentController = TextEditingController(text: widget.post['content'] ?? '');
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'category': selectedCategory,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      // 수정일시 등 필요시 추가
    });
    if (!mounted) return;
    Navigator.pop(context, true); // true 반환하여 필요시 새로고침 유도
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.indigo, fontSize: 16),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
