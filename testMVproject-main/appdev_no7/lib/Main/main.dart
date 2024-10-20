import 'package:appdev_no7/Main/manage_album.dart';
import 'package:appdev_no7/Main/manage_words_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../Login & regist/login_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyVocabApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

class MyVocabApp extends StatelessWidget {
  const MyVocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ComicSans',
        primarySwatch: Colors.blue,
      ),
      home: MainScaffold(),
    );
  }
}

// ---------------- Scaffold หลักสำหรับการนำทาง ----------------
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 2;
  ThemeData _themeData = ThemeData.light(); // ธีมเริ่มต้นคือ Light

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      SettingPage(
        onThemeChanged: (theme) {
          setState(() {
            _themeData = theme;
          });
        },
      ),
      GamePage(),
      VocabularyPage(),
    ];

    return MaterialApp(
      theme: _themeData, // ใช้ _themeData สำหรับการเปลี่ยนธีม
      home: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black,
                child: Text(
                  'MV',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text('My Vocab App'),
            ],
          ),
          backgroundColor: Colors.lightBlue,
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gamepad),
              label: 'Game',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Album',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Updated Setting Page ----------------
class SettingPage extends StatefulWidget {
  final ValueChanged<ThemeData>
      onThemeChanged; // เพิ่ม callback สำหรับการเปลี่ยนธีม

  const SettingPage({super.key, required this.onThemeChanged});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _volume = 50;
  String _selectedTheme = 'White Pastel';

  List<String> themes = ['White Pastel', 'Dark Mode'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Volume control and other settings...
            const SizedBox(height: 30),
            // Theme selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Theme", style: TextStyle(fontSize: 18)),
                DropdownButton<String>(
                  value: _selectedTheme,
                  items: themes.map((String theme) {
                    return DropdownMenuItem<String>(
                      value: theme,
                      child: Text(theme),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTheme = newValue!;
                    });
                    // เปลี่ยนธีมตามค่าที่เลือก
                    if (_selectedTheme == 'Dark Mode') {
                      widget.onThemeChanged(ThemeData.dark());
                    } else {
                      widget.onThemeChanged(ThemeData(
                        primarySwatch: Colors.blue,
                        brightness: Brightness.light,
                      ));
                    }
                  },
                ),
              ],
            ),
             const Spacer(), // ดันปุ่มลงไปด้านล่าง
            ElevatedButton(
              onPressed: () {
            // โค้ดสำหรับ sign out
            Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()), // หน้า Login ของคุณ
            (Route<dynamic> route) => false, // เคลียร์หน้าทั้งหมดใน stack
            );
            },
            child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- หน้าจัดการเกม ----------------

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final List<Map<String, String>> _words = [
    {'word': 'apple', 'translation': 'แอปเปิ้ล'},
    {'word': 'dog', 'translation': 'หมา'},
    {'word': 'cat', 'translation': 'แมว'},
    {'word': 'car', 'translation': 'รถยนต์'},
    {'word': 'sun', 'translation': 'ดวงอาทิตย์'},
    {'word': 'moon', 'translation': 'พระจันทร์'},
    {'word': 'bird', 'translation': 'นก'},
    {'word': 'fish', 'translation': 'ปลา'},
  ];

  List<String> _tiles = [];
  List<bool> _revealed = [];
  int? _firstTileIndex;
  bool _canTap = true;

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    List<String> wordList = [];
    for (var word in _words) {
      wordList.add(word['word']!);
      wordList.add(word['translation']!);
    }
    wordList.shuffle(Random());
    setState(() {
      _tiles = wordList;
      _revealed = List.filled(_tiles.length, false);
      _firstTileIndex = null;
      _canTap = true;
    });
  }

  void _onTileTap(int index) {
    if (!_canTap || _revealed[index]) return;

    setState(() {
      _revealed[index] = true;
    });

    if (_firstTileIndex == null) {
      _firstTileIndex = index;
    } else {
      _canTap = false;
      int firstIndex = _firstTileIndex!;
      String firstValue = _tiles[firstIndex];
      String secondValue = _tiles[index];

      bool isMatch = _checkMatch(firstValue, secondValue);

      if (isMatch) {
        _canTap = true;
        _firstTileIndex = null;
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _revealed[firstIndex] = false;
            _revealed[index] = false;
          });
          _canTap = true;
          _firstTileIndex = null;
        });
      }
    }
  }

  bool _checkMatch(String first, String second) {
    for (var word in _words) {
      if ((first == word['word'] && second == word['translation']) ||
          (second == word['word'] && first == word['translation'])) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เกมจับคู่คำศัพท์'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: _buildGrid(), // แสดงตาราง
            ),
            ElevatedButton(
              onPressed: _setupGame,
              child: const Text('เริ่มเกมใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // ตาราง 4x4
      ),
      itemCount: _tiles.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onTileTap(index),
          child: Card(
            color: _revealed[index] ? Colors.white : Colors.blue,
            child: Center(
              child: Text(
                _revealed[index] ? _tiles[index] : '',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}
// ---------------- หน้าจัดการคำศัพท์ ----------------

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({Key? key}) : super(key: key);

  @override
  _Vocabularystate createState() => _Vocabularystate();
}
class AlbumDetailScreen extends StatelessWidget {
  final String albumName;

  const AlbumDetailScreen({Key? key, required this.albumName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(albumName),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Word',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageWordsPage(albumName: albumName, userId: '',),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
            'Details for album: $albumName'), // คุณสามารถแก้ไขส่วนนี้ให้แสดงคำศัพท์ที่มีในอัลบั้มได้
      ),
    );
  }
}

class _Vocabularystate extends State<VocabularyPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;
  List<String> _albumNames = []; 

  @override
  void initState() {
    super.initState();
    _loadAlbums();  
  }

  void _loadAlbums() async {
    final String userUid = _user!.uid;

    _database.child('users').child(userUid).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          _albumNames = data.keys.map((key) => key.toString()).toList();
        });
      }
    });
  }

  void _deleteAlbum(String albumName) async {
    final String userUid = _user!.uid;

    await _database.child('users').child(userUid).child(albumName).remove(); 
    setState(() {
      _albumNames.remove(albumName); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: Icon(Icons.add), 
            tooltip: 'Add Album',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateAlbumScreen()),
              );
            },
          ),
        ],
      ),
      body: _albumNames.isNotEmpty
          ? ListView.builder(
              itemCount: _albumNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_albumNames[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: const Color.fromARGB(255, 0, 0, 0)),
                    onPressed: () {
                      _deleteAlbum(_albumNames[index]);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailScreen(albumName: _albumNames[index]),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(child: Text('No albums found')),
    );
  }
}  