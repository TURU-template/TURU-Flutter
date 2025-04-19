import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
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
  static const Color darkblue = Color(0xFF0D1A36);
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
    // Apply Open Sans to the entire app
    final openSansTextTheme = GoogleFonts.openSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: openSansTextTheme,
        primaryTextTheme: openSansTextTheme,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
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
    const RadioPage(),
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
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          backgroundColor: TuruColors.navbarBackground,
          selectedItemColor: TuruColors.indigo,
          unselectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedFontSize: 13,
          unselectedFontSize: 13,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            _navItem(
              icon: BootstrapIcons.grid_fill,
              label: 'Beranda',
              index: 0,
            ),
            _navItem(icon: BootstrapIcons.music_note, label: 'Radio', index: 1),
            _navItem(
              icon: BootstrapIcons.person_fill,
              label: 'Profil',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: 24,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: TuruColors.indigo,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 7),
          Icon(icon),
          const SizedBox(height: 6),
        ],
      ),
      label: label,
    );
  }
}
