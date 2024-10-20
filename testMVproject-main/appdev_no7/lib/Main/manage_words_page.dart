import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class ManageWordsPage extends StatefulWidget {
  final String userId; // รับ userId
  final String albumName; // รับ albumName

  // Constructor เพื่อรับค่า userId และ albumName
  ManageWordsPage({required this.userId, required this.albumName});

  @override
  _ManageWordsPageState createState() => _ManageWordsPageState();
}

class _ManageWordsPageState extends State<ManageWordsPage> {
  List<Map<String, String>> _words = [];
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();

  final List<String> _wordTypes = [
    'Nouns',
    'Verbs',
    'Adjectives',
    'Adverbs',
    'Prepositions',
    'Determiners',
    'Pronouns',
    'Conjunctions'
  ];
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  // โหลดคำศัพท์จาก SharedPreferences
  void _loadWords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedWords = prefs.getString('words');

    if (storedWords != null) {
      setState(() {
        _words = List<Map<String, String>>.from(json.decode(storedWords));
      });
    }
  }

  // บันทึกคำศัพท์ลงใน SharedPreferences
  void _saveWordsToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('words', json.encode(_words));
  }

  // บันทึกคำศัพท์ลง Firebase ตามอัลบั้มที่กำหนด
  // ฟังก์ชันบันทึกคำศัพท์ลง Firebase ตามอัลบั้มที่กำหนด
Future<void> _saveWordsToFirebase() async {
  try {
    // ดึง userId จาก Firebase Authentication
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      String albumName = widget.albumName; // ดึง albumName จาก widget
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/$userId/$albumName/vocab");

      for (var word in _words) {
        await ref.child(word['word']!).set({
          "translation": word['translation'],
          "type": word['type'],
        });
      }

      print('Words saved successfully');
    } else {
      print('User is not logged in.');
      // คุณอาจต้องการ redirect ไปยังหน้า login หรือแสดงข้อความแจ้งเตือน
    }
  } catch (error) {
    print('Error saving words: $error');
  }
}

  // ฟังก์ชันเพิ่มคำศัพท์
  void _addWord() {
    if (_selectedType != null &&
        _wordController.text.isNotEmpty &&
        _translationController.text.isNotEmpty) {
      setState(() {
        // เพิ่มคำใหม่ใน List
        _words.add({
          'word': _wordController.text,
          'translation': _translationController.text,
          'type': _selectedType!,
        });
      });

      // บันทึกคำศัพท์ลง SharedPreferences และ Firebase
      _saveWordsToPreferences();
      _saveWordsToFirebase();

      // เคลียร์ TextField หลังจากเพิ่มคำ
      _wordController.clear();
      _translationController.clear();
      _selectedType = null;
    }
  }

  // ฟังก์ชันลบคำศัพท์
  void _removeWord(int index) {
    setState(() {
      _words.removeAt(index);
    });

    _saveWordsToPreferences();
  }

  // ฟังก์ชันแก้ไขคำศัพท์
  void _editWord(int index) {
    _wordController.text = _words[index]['word']!;
    _translationController.text = _words[index]['translation']!;
    _selectedType = _words[index]['type'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _wordController,
                decoration: const InputDecoration(labelText: 'Word'),
              ),
              TextField(
                controller: _translationController,
                decoration: const InputDecoration(labelText: 'Translation'),
              ),
              DropdownButton<String>(
                value: _selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                items: _wordTypes.map<DropdownMenuItem<String>>((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  _words[index]['word'] = _wordController.text;
                  _words[index]['translation'] = _translationController.text;
                  _words[index]['type'] = _selectedType!;
                });
                _saveWordsToPreferences();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Words (${widget.albumName})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _wordController,
                  decoration: const InputDecoration(labelText: 'Word'),
                ),
                TextField(
                  controller: _translationController,
                  decoration: const InputDecoration(labelText: 'Translation'),
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  items:
                      _wordTypes.map<DropdownMenuItem<String>>((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: _selectedType == null ||
                          _wordController.text.isEmpty ||
                          _translationController.text.isEmpty
                      ? null
                      : _addWord,
                  child: const Text('Add Word'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _words.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_words[index]['word']!),
                  subtitle: Text(
                      '${_words[index]['translation']} - ${_words[index]['type']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeWord(index),
                  ),
                  onTap: () => _editWord(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
