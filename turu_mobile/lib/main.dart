// TURU-Flutter/turu_mobile/lib/main.dart:
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/beranda.dart';
import 'pages/radio.dart';
import 'pages/profil.dart';
import 'pages/login.dart';
import 'pages/detail_profil.dart';
import 'pages/edit_profil.dart';
import 'pages/edit_password.dart';
// Ini import untuk file SleepHistoryPage Anda (sudah benar, akan menunjuk ke kelas SleepHistoryPage)
import 'pages/sleep_history_page.dart'; // Import ini sekarang menunjuk ke kelas yang benar
import 'pages/edit_foto.dart';

import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id';
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
  static const Color darkblue = Color(0xFF0D1A36); // Warna darkblue yang sudah ada
  static const Color blue = Color(0xFF35A4DA);
  static const Color purple = Color(0xFF8C4FC2); // Warna ungu
  static const Color pink = Color(0xFFDA5798);   // Warna pink
  static const Color backdrop = Color(0xFF0C0E24);
  static const Color button = Color(0xFF007BFF);
  static const Color grey = Color(0xFFB0BEC5);

  // === TAMBAHKAN DEFINISI WARNA INI ===
  // Menggunakan nilai yang Anda miliki dari kode sleep_history_page sebelumnya
  static const Color cardBackground = Color(0xFF1E1E1E); 
}

class TuruApp extends StatelessWidget {
  const TuruApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('id', 'ID'),
      ],
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainScreen(),
        '/profile_details': (context) => const ProfileDetailsPage(),
        '/edit_foto': (context) => const EditFotoPage(),
        '/edit_profil': (context) => const EditProfilPage(),
        '/edit_password': (context) => const EditPasswordPage(),
        // === PERBAIKAN DI SINI: Gunakan SleepHistoryPage dan tanpa argumen scores ===
        '/history': (context) {
          return const SleepHistoryPage(); // Panggil SleepHistoryPage tanpa argumen data
        },
        // --- AKHIR PERBAIKAN ---
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