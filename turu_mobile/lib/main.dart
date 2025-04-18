import 'package:flutter/material.dart';
import 'beranda_page.dart';
import 'radio_page.dart';
import 'profil_page.dart';
import 'login_page.dart';

void main() {
  runApp(const TuruApp());
}

class TuruColors {
  static const Color primaryBackground = Color(0xFF02021D);
  static const Color navbarBackground = Color(0xFF08082F);

  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textColor2 = Color(0xFF8E8E8E);
  static const Color textBlack = Color(0xFF000000);

  static const Color lilac = Color(0xFF2B194F);
  static const Color indigo = Color(0xFF514FC2);
  static const Color biscay = Color(0xFF18306D);
  static const Color blue = Color(0xFF35A4DA);
  static const Color purple = Color(0xFF8C4FC2);
  static const Color pink = Color(0xFFDA5798);
  static const Color backdrop = Color(0xFF151619);
  static const Color button = Color(0xFF007BFF);
}

class TuruApp extends StatelessWidget {
  const TuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'OpenSans'),
      ),
      home: const LoginPage(), // Change initial route to LoginPage
      routes: {'/main': (context) => const MainScreen()},
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BerandaPage(),
    RadioPage(),
    const ProfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,

      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: TuruColors.navbarBackground,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Radio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
