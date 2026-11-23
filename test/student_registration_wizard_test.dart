import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:student_welfare_fund_app/design/app_theme.dart';
import 'package:student_welfare_fund_app/providers/auth_provider.dart';
import 'package:student_welfare_fund_app/screens/student_registration_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const StudentRegistrationScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('starts on step 1 of 4 with no Back button', (tester) async {
    await _pump(tester);

    // Without easy_localization loaded, tr() returns the key itself.
    expect(find.text('personal_information'), findsOneWidget);
    expect(find.text('back'), findsNothing);
    expect(find.text('continue'), findsOneWidget);
  });

  testWidgets('Continue is blocked while required fields are empty',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('continue'));
    await tester.pumpAndSettle();

    // Still on the personal step, with a validation message shown.
    expect(find.text('personal_information'), findsOneWidget);
    expect(find.text('academic_information'), findsNothing);
    expect(find.text('please_fill_required_fields'), findsOneWidget);
  });
}
