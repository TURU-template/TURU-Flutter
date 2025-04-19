import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/BG_Beranda.svg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        // Main content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Turu Button (State: false for now)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(32),
                      backgroundColor: TuruColors.lilac,
                      side: const BorderSide(
                        color: TuruColors.purple,
                        width: 4,
                      ),
                    ),
                    child: const Text("😊", style: TextStyle(fontSize: 64)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tombol Tidur",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tips Button
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuruColors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadowColor: TuruColors.indigo,
                  elevation: 4,
                ),
                icon: const Icon(Icons.nightlight_round, size: 20),
                label: const Text("Tips Tidur", style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 48),
              const _SectionTitle(title: "Data Tidur"),
              const SizedBox(height: 8),
              const Text(
                "Mulai: 17:49:28 - Selesai: 17:49:29",
                style: TextStyle(color: TuruColors.textColor2),
              ),
              const Text(
                "13 j 20m",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 48),
              const _SectionTitle(title: "Skor Tidur"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("🐨", style: TextStyle(fontSize: 72)),
                  SizedBox(width: 16),
                  Text(
                    "69",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Text(
                "Koala Pemalas",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  "Anda telah tidur lebih dari 12 jam, tidur Anda melebihi batas normal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TuruColors.textColor2),
                ),
              ),

              const SizedBox(height: 48),
              const _SectionTitle(title: "Statistik Tidur"),
              const Text(
                "16 Desember 2024 - 22 Desember 2024",
                style: TextStyle(color: TuruColors.textColor2),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: TuruColors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    "(Area Statistik Placeholder)",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: TuruColors.pink,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
