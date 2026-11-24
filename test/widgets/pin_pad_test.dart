import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/widgets/pin_pad.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('tapping keys reports digits and backspace', (tester) async {
    final digits = <String>[];
    var backspaces = 0;
    await tester.pumpWidget(
      host(PinPad(onDigit: digits.add, onBackspace: () => backspaces++)),
    );

    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('9'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(digits, ['1', '0', '9']);
    expect(backspaces, 1);
  });

  testWidgets('a disabled pad ignores taps', (tester) async {
    final digits = <String>[];
    await tester.pumpWidget(
      host(PinPad(onDigit: digits.add, onBackspace: () {}, enabled: false)),
    );
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(digits, isEmpty);
  });

  testWidgets('shows the optional biometric key', (tester) async {
    await tester.pumpWidget(
      host(
        PinPad(
          onDigit: (_) {},
          onBackspace: () {},
          leading: const Icon(Icons.fingerprint),
        ),
      ),
    );
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
  });

  testWidgets('PinDots fills one dot per typed digit', (tester) async {
    await tester.pumpWidget(host(const PinDots(length: 4, filled: 2)));
    final dots = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(PinDots),
        matching: find.byType(Container),
      ),
    );
    final filled = dots.where((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.color != Colors.transparent;
    });
    expect(dots.length, 4);
    expect(filled.length, 2);
  });
}
