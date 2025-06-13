import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  String selectedCategory = 'Hospital';
  final List<String> categories = [
    'Hospital', 'Cafe', 'Restaurant', 'Tourist Spot', 'Cultural Facility', 'Accommodation',
  ];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and content.')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('posts').add({
      'category': selectedCategory,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'uid': user?.uid,
      'email': user?.email,
    });
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Post', style: TextStyle(color: Colors.indigo, fontSize: 16)),
          )
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
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
                labelText: 'Title',
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
                  labelText: 'Content',
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
