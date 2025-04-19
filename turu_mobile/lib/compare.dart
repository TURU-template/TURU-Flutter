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
    'Burung': 'songs/burung.mp3',
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: ElevatedButton(
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
              // Set or confirm loop mode before playing
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
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
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: buttons),
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
    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/BG_Radio.svg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 100,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection("Derau Warna", [
                            _buildAudioButton("White", "⚪", TuruColors.purple),
                            _buildAudioButton("Blue", "🔵", TuruColors.blue),
                            _buildAudioButton("Brown", "🟤", TuruColors.indigo),
                            _buildAudioButton("Pink", "🩷", TuruColors.pink),
                          ]),
                          _buildSection("Suara Ambiens", [
                            _buildAudioButton("Api", "🔥", TuruColors.pink),
                            _buildAudioButton("Ombak", "🌊", TuruColors.blue),
                            _buildAudioButton(
                              "Burung",
                              "🐦",
                              TuruColors.indigo,
                            ),
                            _buildAudioButton(
                              "Jangkrik",
                              "🦗",
                              TuruColors.lilac,
                            ),
                            _buildAudioButton(
                              "Hujan",
                              "🌧️",
                              TuruColors.biscay,
                            ),
                          ]),
                          _buildSection("Lo-Fi Music", [
                            _buildAudioButton("Monoman", "🎸", TuruColors.blue),
                            _buildAudioButton(
                              "Twilight",
                              "🎵",
                              TuruColors.indigo,
                            ),
                            _buildAudioButton("Yasumu", "🎹", TuruColors.pink),
                          ]),
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
