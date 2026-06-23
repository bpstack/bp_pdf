import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bp_pdf/app/app.dart';

void main() {
  testWidgets('App boots and shows the empty state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IloveoperaApp()));
    await tester.pump();

    expect(find.text('BP PDF'), findsOneWidget);
    expect(find.text('Ningún documento abierto'), findsOneWidget);
  });
}
