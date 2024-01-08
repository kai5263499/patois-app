// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:patois/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

/// A simple implementation of [AssetBundle] that reads files from an asset dir.
///
/// This is meant to be similar to the default [rootBundle] for testing.

void main() {
  const String assetContents = '''
    {
      "lostWords": [
        {
          "definition": "ill-regulated; ill-tempered",
          "description": "The acrasial judge was known for her rants against younger lawyers.",
          "part_of_speech": "adj",
          "word": "acrasial",
          "years": "1851-1851"
        }
      ],
      "allWords": [
        {
          "definition": "South African carnivorous fox-like quadruped",
          "word": "aardwolf"
        }
      ]
    }''';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('LetterCounts loads properly', (WidgetTester tester) async {
    // Load the JSON file
    Map<String, dynamic> data = await loadJson(assetContents);

    expect(data['lostWords'].length, 1);
    expect(data['allWords'].length, 1);
    expect(data['lostWords']['acrasial'].word, 'acrasial');
    expect(data['allWords']['aardwolf'].word, 'aardwolf');
    expect(data['lostWordsLetterCounts']['A'], 1);
    expect(data['allWordsLetterCounts']['A'], 1);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      DataProvider(
        data: data,
        child: Provider(
          create: (_) => WordModeNotifier(),
          child: const MyApp(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that LetterCounts is present.
    expect(find.byType(LetterCounts), findsOneWidget);

    // Verify that at least one child with the letter 'A' and a count greater than 0 is present.
    expect(find.text('A: 1'), findsOneWidget);
  });
}
