import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.indigo),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.indigo),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings icon clicked')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.indigo),
            title: const Text('Change Language (EN/KR)'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.indigo),
            title: const Text('Notification Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.indigo),
            title: const Text('Manage Bookmarks'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.indigo),
            title: const Text('Terms & Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.indigo),
            title: const Text('Feedback / Contact Us'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.indigo),
            title: const Text('Logout'),
            onTap: () async {
              try {
                await GoogleSignIn().signOut();
              } catch (_) {}
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You have been logged out.')),
                );
              }
            },
          ),
          const Divider(height: 30),
          Center(
            child: Text(
              'App Version v1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
