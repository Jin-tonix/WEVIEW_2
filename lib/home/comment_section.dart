import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': user?.uid,
      'email': user?.email,
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "댓글",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "댓글을 입력하세요",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.indigo),
              onPressed: () => _addComment(_commentController.text),
            )
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: commentsRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final comments = snapshot.data!.docs;
              if (comments.isEmpty) return const Text("아직 댓글이 없습니다.");
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentTile(
                    postId: widget.postId,
                    commentId: comment.id,
                    comment: comment,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CommentTile extends StatefulWidget {
  final String postId;
  final String commentId;
  final QueryDocumentSnapshot comment;

  const CommentTile({
    super.key,
    required this.postId,
    required this.commentId,
    required this.comment,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _showReplyField = false;
  final TextEditingController _replyController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _addReply(String replyText) async {
    if (replyText.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('replies')
        .add({
      'text': replyText,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': user?.uid,
      'email': user?.email,
    });
    _replyController.clear();
    setState(() => _showReplyField = false);
  }

  // 댓글 수정
  void _editComment(BuildContext context, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('수정'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .doc(widget.commentId)
                  .update({'text': controller.text.trim()});
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // 댓글 삭제
  Future<void> _deleteComment() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final repliesRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false);

    final commentData = widget.comment.data() as Map<String, dynamic>;
    final isMyComment = commentData['uid'] == user?.uid;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(commentData['text'] ?? ''),
            Row(
              children: [
                TextButton(
                  child: const Text("답글", style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    setState(() {
                      _showReplyField = !_showReplyField;
                    });
                  },
                ),
                if (isMyComment) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editComment(context, commentData['text']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: _deleteComment,
                  ),
                ],
              ],
            ),
            if (_showReplyField)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: "답글을 입력하세요",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, size: 18, color: Colors.indigo),
                    onPressed: () => _addReply(_replyController.text),
                  )
                ],
              ),
            // 대댓글 리스트
            StreamBuilder<QuerySnapshot>(
              stream: repliesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final replies = snapshot.data!.docs;
                if (replies.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: replies
                        .map((reply) => ReplyTile(
                      postId: widget.postId,
                      commentId: widget.commentId,
                      reply: reply,
                    ))
                        .toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ReplyTile extends StatelessWidget {
  final String postId;
  final String commentId;
  final QueryDocumentSnapshot reply;

  ReplyTile({
    required this.postId,
    required this.commentId,
    required this.reply,
    super.key,
  });

  final user = FirebaseAuth.instance.currentUser;

  void _editReply(BuildContext context, String replyId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('대댓글 수정'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('수정'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .doc(commentId)
                  .collection('replies')
                  .doc(replyId)
                  .update({'text': controller.text.trim()});
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReply(String replyId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final replyData = reply.data() as Map<String, dynamic>;
    final isMyReply = replyData['uid'] == user?.uid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "- ${replyData['text'] ?? ''}",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        if (isMyReply) ...[
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () => _editReply(context, reply.id, replyData['text']),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 16),
            onPressed: () => _deleteReply(reply.id),
          ),
        ]
      ],
    );
  }
}
