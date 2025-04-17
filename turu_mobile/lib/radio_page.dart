import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RadioPage extends StatelessWidget {
  const RadioPage({super.key});

  Widget _buildAudioButton(String label, String emoji, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text('$label $emoji', style: const TextStyle(fontSize: 16)),
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
        Wrap(spacing: 8, runSpacing: 8, children: buttons),
        const SizedBox(height: 24),
      ],
    );
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection("Derau Warna", [
                            _buildAudioButton(
                              "White",
                              "⚪",
                              const Color(0xFFE5E5E5),
                            ),
                            _buildAudioButton(
                              "Blue",
                              "🔵",
                              const Color(0xFF35A4DA),
                            ),
                            _buildAudioButton(
                              "Brown",
                              "🟤",
                              const Color(0xFF6F4E37),
                            ),
                            _buildAudioButton(
                              "Pink",
                              "🩷",
                              const Color(0xFFDA5798),
                            ),
                          ]),
                          _buildSection("Suara Ambiens", [
                            _buildAudioButton(
                              "Api",
                              "🔥",
                              const Color(0xFFDA5798),
                            ),
                            _buildAudioButton(
                              "Ombak",
                              "🌊",
                              const Color(0xFF35A4DA),
                            ),
                            _buildAudioButton(
                              "Burung",
                              "🐦",
                              const Color(0xFF514FC2),
                            ),
                            _buildAudioButton(
                              "Jangkrik",
                              "🦗",
                              const Color(0xFF2B194F),
                            ),
                            _buildAudioButton(
                              "Hujan",
                              "🌧️",
                              const Color(0xFF18306D),
                            ),
                          ]),
                          _buildSection("Lo-Fi Music", [
                            _buildAudioButton(
                              "Monoman",
                              "🎸",
                              const Color(0xFF35A4DA),
                            ),
                            _buildAudioButton(
                              "Twilight",
                              "🎵",
                              const Color(0xFF514FC2),
                            ),
                            _buildAudioButton(
                              "Yasumu",
                              "🎹",
                              const Color(0xFFDA5798),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Timer Button
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFFDA5798),
              onPressed: () {
                // TODO: open timer dialog or route
              },
              icon: const Icon(Icons.timer),
              label: const Text("Timer"),
            ),
          ),
        ],
      ),
    );
  }
}
