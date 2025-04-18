import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlaying;
  bool _isPlaying = false;

  final Map<String, String> soundSources = {
    // Derau Warna
    'White': 'songs/noise_white.mp3',
    'Blue': 'songs/noise_blue.mp3',
    'Brown': 'songs/noise_brown.mp3',
    'Pink': 'songs/noise_pink.mp3',

    // Suara Ambiens
    'Api': 'songs/Api.mp3',
    'Ombak': 'songs/Ombak.mp3',
    'Burung': 'songs/Burung.mp3',
    'Jangkrik': 'songs/Jangkrik.mp3',
    'Hujan': 'songs/Hujan.mp3',

    // Lo-Fi Music
    'Monoman': 'songs/Monoman.mp3',
    'Twilight': 'songs/Twilight.mp3',
    'Yasumu': 'songs/Yasumu.mp3',
  };

  @override
  void initState() {
    super.initState();
    // Set the release mode to loop by default
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Widget _buildAudioButton(String label, String emoji, Color activeColor) {
    final bool isCurrentlyPlaying = _currentPlaying == label && _isPlaying;
    final Color buttonColor = isCurrentlyPlaying ? activeColor : Colors.white;
    final Color textColor = isCurrentlyPlaying ? Colors.white : activeColor;
    final BorderSide borderSide = BorderSide(color: activeColor, width: 1.0);

    return ElevatedButton(
      onPressed: () async {
        String? path = soundSources[label];
        if (path != null) {
          if (_isPlaying && _currentPlaying == label) {
            await _audioPlayer.stop();
            setState(() {
              _isPlaying = false;
              _currentPlaying = null;
            });
          } else {
            await _audioPlayer.stop();
            await _audioPlayer.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer.play(AssetSource(path));
            setState(() {
              _isPlaying = true;
              _currentPlaying = label;
            });
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: !isCurrentlyPlaying ? borderSide : BorderSide.none,
        ),
        elevation: isCurrentlyPlaying ? 3 : 0,
      ),
      child: Text(
        '$label $emoji',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: buttons.length,
          itemBuilder: (context, index) {
            return _buildAudioButton(
              buttons[index]['label'],
              buttons[index]['emoji'],
              buttons[index]['color'],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> derauButtons = [
      {'label': 'White', 'emoji': '⚪', 'color': TuruColors.purple},
      {'label': 'Blue', 'emoji': '🔵', 'color': TuruColors.blue},
      {'label': 'Brown', 'emoji': '🟤', 'color': TuruColors.indigo},
      {'label': 'Pink', 'emoji': '🩷', 'color': TuruColors.pink},
    ];

    final List<Map<String, dynamic>> ambiensButtons = [
      {'label': 'Api', 'emoji': '🔥', 'color': TuruColors.pink},
      {'label': 'Ombak', 'emoji': '🌊', 'color': TuruColors.blue},
      {'label': 'Burung', 'emoji': '🐦', 'color': TuruColors.indigo},
      {'label': 'Jangkrik', 'emoji': '🦗', 'color': TuruColors.lilac},
      {'label': 'Hujan', 'emoji': '🌧️', 'color': TuruColors.biscay},
    ];

    final List<Map<String, dynamic>> lofiButtons = [
      {'label': 'Monoman', 'emoji': '🎸', 'color': TuruColors.blue},
      {'label': 'Twilight', 'emoji': '🎵', 'color': TuruColors.indigo},
      {'label': 'Yasumu', 'emoji': '🎹', 'color': TuruColors.pink},
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/BG_Radio.svg',
              fit: BoxFit.cover,
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 60,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection("Derau Warna", derauButtons),
                          _buildSection("Suara Ambiens", ambiensButtons),
                          _buildSection("Lo-Fi Music", lofiButtons),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Timer Button (Vertical Layout, larger)
          Positioned(
            bottom: 80,
            right: 20,
            child: SizedBox(
              width: 80,
              height: 80,
              child: FloatingActionButton(
                backgroundColor: TuruColors.pink,
                onPressed: () {
                  // TODO: implement timer functionality
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.timer, size: 28),
                    SizedBox(height: 6),
                    Text(
                      "Timer",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
