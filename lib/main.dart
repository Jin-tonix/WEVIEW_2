import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'home/homescreen.dart';  // HomeScreen을 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env"); // 환경 변수 로딩

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/', // 앱이 시작될 때 보여줄 화면을 지정
      routes: {
        '/': (context) => const HomeScreen(), // 로그인 없이 바로 홈 화면을 보여줌
        // 필요한 다른 화면들을 여기에 추가
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// import 'firebase_options.dart';
// import 'auth/login_screen.dart';
// import 'auth/signup_screen.dart';
// import 'home/homescreen.dart';
//
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: "assets/.env"); // 환경 변수 로딩
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//
//   runApp(const MyApp());
// }
//
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter App',
//       initialRoute: '/', // 앱이 시작될 때 보여줄 화면을 지정
//       routes: {
//         '/': (context) => const AuthCheck(), // AuthCheck로 로그인 상태 확인
//         '/login': (context) => const LoginScreen(), // 로그인 화면
//         '/signup': (context) => const SignupScreen(), // 회원가입 화면
//         '/home': (context) => const HomeScreen(), // 홈 화면
//       },
//     );
//   }
// }
//
// // 로그인 상태를 확인하는 위젯
// class AuthCheck extends StatelessWidget {
//   const AuthCheck({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         // 로딩 중일 때
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//         // 에러가 발생했을 때
//         else if (snapshot.hasError) {
//           return const Scaffold(
//             body: Center(child: Text('로그인 상태 확인 중 오류 발생')),
//           );
//         }
//         // 로그인된 상태일 때
//         else if (snapshot.hasData) {
//           return const HomeScreen();  // 로그인된 경우 홈 화면으로
//         }
//         // 로그인되지 않은 상태일 때
//         else {
//           return const LoginScreen();  // 로그인되지 않은 경우 로그인 화면으로
//         }
//       },
//     );
//   }
// }