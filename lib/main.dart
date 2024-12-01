import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WordOfTheDayPage(),      
    );
  }
}

class WordOfTheDayPage extends StatefulWidget {
  const WordOfTheDayPage({Key? key}) : super(key: key);

  @override
  _WordOfTheDayPageState createState() => _WordOfTheDayPageState();
}

class _WordOfTheDayPageState extends State<WordOfTheDayPage> {
  bool isLoading = true;
  Map<int, List<String>> groupedWords = {};

  @override
  void initState() {
    super.initState();
    fetchWordData();
  }

  Future<void> fetchWordData() async {
    const String url =
        'https://shoptips24.com/binance-word-of-the-day-answer-today/';
    const int minLength = 3; // Minimum word length
    const int maxLength = 8; // Maximum word length

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final filteredWords =
            _extractWords(response.body, minLength, maxLength);
        setState(() {
          groupedWords = _groupWordsByLength(filteredWords);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching data: $e');
    }
  }

  List<String> _extractWords(String html, int minLength, int maxLength) {
    final document = html_parser.parse(html);
    final words = <String>{}; // Use a Set to avoid duplicates

    // Extract words from <ul> and <li> elements
    final listItems = document.querySelectorAll('ul li');

    for (var item in listItems) {
      final word = item.text.trim();
      if (word.isNotEmpty &&
          word.length >= minLength &&
          word.length <= maxLength &&
          word == word.toUpperCase()) {
        words.add(word); // Add to Set to avoid duplicates
      }
    }

    return words.toList(); // Convert Set to List
  }

  Map<int, List<String>> _groupWordsByLength(List<String> words) {
    Map<int, List<String>> groupedWords = {};

    for (var word in words) {
      int length = word.length;
      groupedWords.putIfAbsent(length, () => []).add(word);
    }

    // Sort the words within each length group
    groupedWords.forEach((key, value) {
      value.sort();
    });

    return groupedWords;
  }

  void _refreshData() {
    setState(() {
      isLoading = true;
      groupedWords.clear();
    });
    fetchWordData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Binance Words Today"),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedWords.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: (groupedWords.keys.toList()
                        ..sort()) // Sort keys first
                      .map((length) =>
                          _buildWordList(length, groupedWords[length]!))
                      .toList(),
                ),
              
    );
    
  }

  Widget _buildWordList(int length, List<String> words) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$length Letters Words',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8.0, // Space between words
          runSpacing: 4.0, // Space between lines
          children: words.map((word) {
            return _buildStyledWord(word);
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStyledWord(String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        word,
        style: const TextStyle(
            fontSize: 16.0, color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}
