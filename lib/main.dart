// ignore_for_file: constant_identifier_names

import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

enum WordMode { all, lost }

const String DEFINITION_TEXT = 'Definition:';
const String PART_OF_SPEECH_TEXT = 'Part of Speech:';
const String YEARS_USED_TEXT = 'Years Used:';

const String ALL_WORDS_KEY = 'allWords';
const String LOST_WORDS_KEY = 'lostWords';
const String ALL_WORDS_LETTER_COUNTS_KEY = 'allWordsLetterCounts';
const String LOST_WORDS_LETTER_COUNTS_KEY = 'lostWordsLetterCounts';

const String PATOIS_TITLE = 'Patois';
const String PATOIS_SUBTITLE =
    'a: a dialect other than the standard or literary dialect';

class AllWord {
  final String word;
  final String definition;

  AllWord({required this.word, required this.definition});

  factory AllWord.fromJson(Map<String, dynamic> json) {
    return AllWord(
      word: json['word'],
      definition: json['definition'],
    );
  }
}

class LostWord {
  final String word;
  final String definition;
  final String description;
  final String partOfSpeech;
  final String years;

  LostWord(
      {required this.word,
      required this.definition,
      required this.description,
      required this.partOfSpeech,
      required this.years});

  factory LostWord.fromJson(Map<String, dynamic> json) {
    return LostWord(
      word: json['word'],
      definition: json['definition'],
      description: json['description'],
      partOfSpeech: expandPartOfSpeech(json['part_of_speech']),
      years: json['years'],
    );
  }
}

class JsonData {
  final List<AllWord> allWords;
  final List<LostWord> lostWords;

  JsonData({required this.allWords, required this.lostWords});

  factory JsonData.fromJson(Map<String, dynamic> json) {
    var allWordsJson = json[ALL_WORDS_KEY] as List;
    var lostWordsJson = json[LOST_WORDS_KEY] as List;

    List<AllWord> allWordsList =
        allWordsJson.map((i) => AllWord.fromJson(i)).toList();
    List<LostWord> lostWordsList =
        lostWordsJson.map((i) => LostWord.fromJson(i)).toList();

    return JsonData(
      allWords: allWordsList,
      lostWords: lostWordsList,
    );
  }
}

Future<Map<String, dynamic>> loadJson(String? jsonString) async {
  jsonString ??= await rootBundle.loadString('assets/phronthistery.json');
  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  JsonData data = JsonData.fromJson(jsonData);

  Map<String, AllWord> allWordsMap =
      data.allWords.fold<Map<String, AllWord>>({}, (map, word) {
    map[word.word] = word;
    return map;
  });

  Map<String, LostWord> lostWordsMap =
      data.lostWords.fold<Map<String, LostWord>>({}, (map, word) {
    map[word.word] = word;
    return map;
  });

  Map<String, int> allWordsLetterCountMap = {};
  for (var word in allWordsMap.keys) {
    String firstLetter = word[0].toUpperCase();
    if (!allWordsLetterCountMap.containsKey(firstLetter)) {
      allWordsLetterCountMap[firstLetter] = 1;
    } else {
      allWordsLetterCountMap[firstLetter] =
          (allWordsLetterCountMap[firstLetter] ?? 0) + 1;
    }
  }

  Map<String, int> lostWordsLetterCountMap = {};
  for (var word in lostWordsMap.keys) {
    String firstLetter = word[0].toUpperCase();
    if (!lostWordsLetterCountMap.containsKey(firstLetter)) {
      lostWordsLetterCountMap[firstLetter] = 1;
    } else {
      lostWordsLetterCountMap[firstLetter] =
          (lostWordsLetterCountMap[firstLetter] ?? 0) + 1;
    }
  }

  return {
    ALL_WORDS_KEY: allWordsMap,
    LOST_WORDS_KEY: lostWordsMap,
    ALL_WORDS_LETTER_COUNTS_KEY: allWordsLetterCountMap,
    LOST_WORDS_LETTER_COUNTS_KEY: lostWordsLetterCountMap,
  };
}

class WordModeNotifier extends ValueNotifier<WordMode> {
  WordModeNotifier() : super(WordMode.all);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> data = await loadJson(null);

  runApp(DataProvider(
    data: data,
    child: Provider(
      create: (_) => WordModeNotifier(),
      child: const MyApp(),
    ),
  ));
}

class DataProvider extends InheritedWidget {
  final Map<String, dynamic> data;

  const DataProvider({super.key, required this.data, required super.child});

  static DataProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DataProvider>();
  }

  @override
  bool updateShouldNotify(DataProvider oldWidget) {
    return true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WordModeNotifier>(
      create: (context) => WordModeNotifier(),
      child: MaterialApp(
        title: PATOIS_TITLE,
        theme: ThemeData(
          primarySwatch: Colors.red,
        ),
        home: const MyHomePage(
          title: PATOIS_TITLE,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? selectedWord;
  final bool? searchedForWord;

  const MyHomePage({
    super.key,
    required this.title,
    this.selectedWord,
    this.searchedForWord,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedWord;
  bool? searchedForWord;

  @override
  void initState() {
    super.initState();
    selectedWord = widget.selectedWord;
    searchedForWord = widget.searchedForWord;
  }

  void pickRandomWord(WordMode currentWordMode) {
    if (currentWordMode == WordMode.lost) {
      Map<String, LostWord> lostWords =
          DataProvider.of(context)!.data[LOST_WORDS_KEY];
      var keys = lostWords.keys.toList();
      var randomKey = keys[Random().nextInt(keys.length)];
      setState(() {
        selectedWord = randomKey;
      });
      return;
    }

    Map<String, AllWord> allWords =
        DataProvider.of(context)!.data[ALL_WORDS_KEY];
    var keys = allWords.keys.toList();
    var randomKey = keys[Random().nextInt(keys.length)];
    setState(() {
      selectedWord = randomKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    WordModeNotifier wordModeNotifier = Provider.of<WordModeNotifier>(context);
    var currentWordMode = wordModeNotifier.value;

    /// Checks if the [searchedForWord] is not set and calls the [pickRandomWord] function with the [currentWordMode] as an argument.
    /// If [searchedForWord] is set to `true`, the [pickRandomWord] function will not be called.
    if (!(searchedForWord ?? false)) {
      pickRandomWord(currentWordMode);
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Stack(children: <Widget>[
        // The background image
        Image.asset(
          'assets/images/parchment-background.png',
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: 90.0,
            backgroundColor: Colors.red,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          launchURL(Uri.parse('https://www.phrontistery.info')),
                      child: Text(
                        PATOIS_TITLE,
                        style: GoogleFonts.comfortaa(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: WordSearchDelegate(),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(PATOIS_SUBTITLE,
                          style: GoogleFonts.comfortaa(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          )),
                    ),
                  ],
                )
              ],
            ),
          ),
          body: Container(
              color: const Color.fromARGB(96, 255, 255, 255),
              child: Center(
                child: GestureDetector(
                  onTap: () => {
                    if (searchedForWord ?? false)
                      launchURL(Uri.parse(
                          'https://www.oed.com/search/dictionary/?scope=Entries&q=$selectedWord'))
                    else
                      pickRandomWord(currentWordMode)
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Aligns children along the horizontal axis
                    mainAxisAlignment: MainAxisAlignment
                        .start, // Aligns children along the vertical axis
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(
                            20.0), // Adjust the value as needed
                        child: Text(
                          selectedWord ?? '',
                          style: GoogleFonts.comfortaa(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(
                            20.0), // Adjust the value as needed
                        child: buildWordDetailsWidget(
                            context, currentWordMode, selectedWord ?? ''),
                      ),
                    ],
                  ),
                ),
              )),
          bottomNavigationBar: Container(
            color: const Color.fromARGB(159, 244, 67, 54),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: wordModeNotifier.value == WordMode.all
                            ? Colors.white70
                            : Colors.black,
                      ),
                      onPressed: () {
                        wordModeNotifier.value = WordMode.all;
                      },
                      child: const Text('All'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: wordModeNotifier.value == WordMode.lost
                            ? Colors.white70
                            : Colors.black,
                      ),
                      child: const Text('Lost'),
                      onPressed: () {
                        wordModeNotifier.value = WordMode.lost;
                      },
                    ),
                  ],
                ),
                // A-Z strip
                const LetterCounts(),
              ],
            ),
          ),
        ),
      ]);
    });
  }
}

class LetterCounts extends StatelessWidget {
  const LetterCounts({super.key});

  @override
  Widget build(BuildContext context) {
    WordModeNotifier wordModeNotifier = Provider.of<WordModeNotifier>(context);

    // Now you can use wordModeNotifier to get or set the current WordMode
    WordMode currentMode = wordModeNotifier.value;

    Map<String, dynamic> data = DataProvider.of(context)!.data;
    Map<String, int> letterCounts = data[ALL_WORDS_LETTER_COUNTS_KEY];
    if (currentMode == WordMode.lost) {
      letterCounts = data[LOST_WORDS_LETTER_COUNTS_KEY];
    }

    var sortedKeys = letterCounts.keys.toList()..sort();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          String letter = sortedKeys.elementAt(index);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => WordListScreen(
                        letter: letter, currentMode: currentMode)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$letter: ${letterCounts[letter]}'),
            ),
          );
        },
      ),
    );
  }
}

class WordListScreen extends StatelessWidget {
  final String letter;
  final WordMode currentMode;

  const WordListScreen(
      {super.key, required this.letter, required this.currentMode});

  @override
  Widget build(BuildContext context) {
    if (currentMode == WordMode.lost) {
      Map<String, LostWord> data =
          DataProvider.of(context)!.data[LOST_WORDS_KEY];
      var words = data.keys
          .where((word) => word.startsWith(letter.toLowerCase()))
          .toList();
      words.sort();
      return Scaffold(
        appBar: AppBar(title: Text('Words starting with $letter')),
        body: ListView.builder(
          itemCount: words.length,
          itemBuilder: (context, index) {
            var word = words[index];
            return buildWordDetailsTile(context, currentMode, word);
          },
        ),
      );
    } else {
      Map<String, AllWord> data = DataProvider.of(context)!.data[ALL_WORDS_KEY];
      var words = data.keys
          .where((word) => word.startsWith(letter.toLowerCase()))
          .toList();
      words.sort();
      return Scaffold(
        appBar: AppBar(title: Text('Words starting with $letter')),
        body: ListView.builder(
          itemCount: words.length,
          itemBuilder: (context, index) {
            var word = words[index];
            return buildWordDetailsTile(context, currentMode, word);
          },
        ),
      );
    }
  }
}

Future<void> launchURL(Uri uri) async {
  if (!await launchUrl(uri)) {
    throw Exception('Could not launch $uri');
  }
}

Widget buildWordDetailsWidget(
    BuildContext context, WordMode currentWordMode, String word) {
  final TextStyle leftColStyle = GoogleFonts.comfortaa(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  if (currentWordMode == WordMode.all) {
    var definition =
        DataProvider.of(context)!.data[ALL_WORDS_KEY][word].definition;

    return Row(
      children: [
        SizedBox(
          width: 150, // Set your desired maximum width here
          child: Text(
            DEFINITION_TEXT,
            style: leftColStyle,
          ),
        ),
        Flexible(
          child: Text(definition),
        ),
      ],
    );
  } else if (currentWordMode == WordMode.lost) {
    var definition =
        DataProvider.of(context)!.data[LOST_WORDS_KEY][word].definition;
    var partOfSpeech =
        DataProvider.of(context)!.data[LOST_WORDS_KEY][word].partOfSpeech;
    var yearsUsed = DataProvider.of(context)!.data[LOST_WORDS_KEY][word].years;

    double? leftColWidth = 180;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: leftColWidth, // Set your desired maximum width here
              child: Text(
                DEFINITION_TEXT,
                style: leftColStyle,
              ),
            ),
            Flexible(
              child: Text(definition),
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: leftColWidth, // Set your desired maximum width here
              child: Text(
                PART_OF_SPEECH_TEXT,
                style: leftColStyle,
              ),
            ),
            Flexible(
              child: Text(partOfSpeech),
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: leftColWidth, // Set your desired maximum width here
              child: Text(
                YEARS_USED_TEXT,
                style: leftColStyle,
              ),
            ),
            Flexible(
              child: Text(yearsUsed),
            ),
          ],
        ),
      ],
    );
  } else {
    throw Exception('Invalid WordMode');
  }
}

String expandPartOfSpeech(String abbreviation) {
  switch (abbreviation) {
    case 'v':
      return 'verb';
    case 'n':
      return 'noun';
    case 'adj':
      return 'adjective';
    case 'adv':
      return 'adverb';
    case 'npl':
      return 'noun plural';
    default:
      return abbreviation;
  }
}

Widget buildWordDetailsTile(
    BuildContext context, WordMode currentWordMode, String word) {
  if (currentWordMode == WordMode.all) {
    var definition =
        DataProvider.of(context)!.data[ALL_WORDS_KEY][word].definition;

    return ListTile(
      title: Text(word),
      subtitle: Text(definition),
    );
  } else if (currentWordMode == WordMode.lost) {
    var definition =
        DataProvider.of(context)!.data[LOST_WORDS_KEY][word].definition;
    var partOfSpeech =
        DataProvider.of(context)!.data[LOST_WORDS_KEY][word].partOfSpeech;
    var yearsUsed = DataProvider.of(context)!.data[LOST_WORDS_KEY][word].years;

    return ListTile(
      title: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(word),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              child: Text(partOfSpeech),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(yearsUsed),
            ),
          ),
        ],
      ),
      subtitle: Text(definition),
    );
  } else {
    throw Exception('Invalid WordMode');
  }
}

class WordSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    Map<String, dynamic> data = DataProvider.of(context)!.data;
    Map<String, AllWord> allWords = data[ALL_WORDS_KEY];
    Map<String, LostWord> lostWords = data[LOST_WORDS_KEY];

    WordModeNotifier wordModeNotifier = Provider.of<WordModeNotifier>(context);

    final suggestions = allWords.values
        .where((word) => word.definition.contains(query))
        .map((word) => ListTile(
              title: Row(
                children: [
                  Text(
                    word.word,
                  ),
                ],
              ),
              subtitle: Text(
                word.definition,
              ),
              onTap: () {
                // Set the randomWord and wordModeNotifier.value to match the clicked word
                wordModeNotifier.value = WordMode.all;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHomePage(
                      selectedWord: word.word,
                      searchedForWord: true,
                      title: PATOIS_TITLE,
                    ),
                  ),
                );
              },
            ))
        .toList()
      ..addAll(lostWords.values
          .where((word) => word.definition.contains(query))
          .map((word) => ListTile(
                title: Row(
                  children: [
                    Text(
                      word.word,
                    ),
                    const Spacer(), // Add a Spacer widget to push the next widget to the right
                    const Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.not_listed_location,
                        color: Colors.green,
                      ), // Add the Text('All') widget
                    ),
                  ],
                ),
                subtitle: Text(
                  word.definition,
                ),
                onTap: () {
                  // Set the randomWord and wordModeNotifier.value to match the clicked word
                  wordModeNotifier.value = WordMode.lost;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        selectedWord: word.word,
                        searchedForWord: true,
                        title: PATOIS_TITLE,
                      ),
                    ),
                  );
                },
              ))
          .toList());

    suggestions.sort((a, b) {
      final aWord = (a.title as Row).children[0] as Text;
      final bWord = (b.title as Row).children[0] as Text;
      return aWord.data!.compareTo(bWord.data!);
    });

    return ListView(children: suggestions);
  }
}
