// TURU-Flutter/turu_mobile/lib/main.dart:
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'pages/beranda.dart';
import 'pages/radio.dart';
import 'pages/profil.dart';
import 'pages/login.dart';
import 'pages/detail_profil.dart';
import 'pages/edit_profil.dart';
import 'pages/edit_password.dart';
import 'pages/sleep_history_page.dart';
// Import the notification service
import 'services/notification_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the NotificationService
  await NotificationService().initialize();

  runApp(const TuruApp());
}

class TuruColors {
  static const Color primaryBackground = Color(0xFF04051F);
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
  static const Color backdrop = Color(0xFF0C0E24);
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
      routes: {
        '/login': (context) => const LoginPage(), // Added login route
        '/main': (context) => const MainScreen(),
        '/profile_details': (context) => const ProfileDetailsPage(),
        '/edit_profil': (context) => const EditProfilPage(),
        '/edit_password': (context) => const EditPasswordPage(),
        '/history': (context) {
          return HistorySleepPage(scores: [88, 90, 75, 80, 92, 85, 70]);
        },
      },
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
        height: 65,
        child: BottomNavigationBar(
          backgroundColor: TuruColors.navbarBackground,
          selectedItemColor: TuruColors.indigo,
          unselectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
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
              width: 20,
              height: 2,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: TuruColors.indigo,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 6),
          Icon(icon, size: 20),
          const SizedBox(height: 4),
        ],
      ),
      label: label,
    );
  }
}
