import 'package:flutter/material.dart';
import 'login_screen.dart'; // 로그인 화면으로 돌아가기

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 돌아가기
          },
          child: const Text('구글로 회원가입'),
        ),
      ),
    );
  }
}
