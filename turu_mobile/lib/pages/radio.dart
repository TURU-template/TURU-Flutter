import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../main.dart';
import 'dart:async';

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlaying;
  bool _isPlaying = false;

  Timer? _timer;
  int? _remainingSeconds;
  int? _selectedDuration;

  bool _showTimerOptions = false;

  final Map<String, String> soundSources = {
    // Derau Warna
    'White': 'songs/white.mp3',
    'Blue': 'songs/blue.mp3',
    'Brown': 'songs/brown.mp3',
    'Pink': 'songs/pink.mp3',

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
    final BorderSide borderSide = BorderSide(
      color: activeColor,
      width: 3.0,
    ); // Increased border width

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
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 16,
        ), // Smaller vertical padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: !isCurrentlyPlaying ? borderSide : BorderSide.none,
        ),
        elevation: isCurrentlyPlaying ? 3 : 0,
        minimumSize: Size.zero, // Make the button size adapt to content
        tapTargetSize:
            MaterialTapTargetSize
                .shrinkWrap, // Remove extra padding around the button
      ),
      child: Text(
        '$label $emoji',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            childAspectRatio: 3.0, // Adjust aspect ratio for smaller height
            crossAxisSpacing: 10,
            mainAxisSpacing: 8, // Adjust main axis spacing
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

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
      _selectedDuration = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == null) return;
      if (_remainingSeconds! > 0) {
        setState(() {
          _remainingSeconds = _remainingSeconds! - 1;
        });
      } else {
        _stopAudioAndTimer();
      }
    });
  }

  void _stopAudioAndTimer() async {
    await _audioPlayer.stop();
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentPlaying = null;
      _remainingSeconds = null;
      _selectedDuration = null;
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> derauButtons = [
      {'label': 'White', 'emoji': '⚪', 'color': TuruColors.purple},
      {'label': 'Blue', 'emoji': '🔵', 'color': TuruColors.blue},
      {'label': 'Brown', 'emoji': '🟤', 'color': TuruColors.indigo},
      {'label': 'Pink', 'emoji': '❤️', 'color': TuruColors.pink},
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

          // Timer Options (floating left of timer button)
          if (_showTimerOptions && _remainingSeconds == null)
            Positioned(
              bottom: 80,
              right: 120, // Geser ke kiri dari tombol timer
              child: Material(
                color: Colors.transparent,
                child: Row(
                  children: [
                    _buildTimerOption(5),
                    const SizedBox(width: 12),
                    _buildTimerOption(10),
                    const SizedBox(width: 12),
                    _buildTimerOption(15),
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
                heroTag: null, // Add unique heroTag
                backgroundColor: TuruColors.pink,
                onPressed: () {
                  if (_remainingSeconds != null) {
                    _stopAudioAndTimer();
                    setState(() {
                      _showTimerOptions = false;
                    });
                  } else {
                    setState(() {
                      _showTimerOptions = !_showTimerOptions;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      _remainingSeconds != null
                          ? _formatDuration(_remainingSeconds!)
                          : "Timer",
                      style: const TextStyle(
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

  Widget _buildTimerOption(int minutes) {
    final bool isSelected = _selectedDuration == minutes * 60;
    return ElevatedButton(
      onPressed: () {
        _startTimer(minutes * 60);
        setState(() {
          _showTimerOptions = false;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: TuruColors.pink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        elevation: isSelected ? 4 : 0,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text('${minutes}m'),
    );
  }
}
