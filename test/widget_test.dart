import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weview/main.dart';

void main() {
  testWidgets('앱이 정상적으로 실행되는지 확인', (WidgetTester tester) async {
    // MyApp을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget( MyApp());

    // 앱이 정상적으로 실행되었는지 확인하기 위해 텍스트 확인
    expect(find.text('WEVIEW'), findsOneWidget);  // 'WEVIEW' 텍스트가 화면에 있는지 확인
  });
}
