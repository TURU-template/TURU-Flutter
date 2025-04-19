import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import '../main.dart'; // Assuming TuruColors is defined here

class BerandaPage extends StatelessWidget {
  final bool? isSleeping;
  final DateTime? startTime;
  final int? sleepScore;
  final String? mascot;
  final String? mascotName;
  final String? mascotDescription;
  final List<int>? weeklyScores;
  final List<String>? dayLabels;

  const BerandaPage({
    super.key,
    this.isSleeping,
    this.startTime,
    this.sleepScore,
    this.mascot,
    this.mascotName,
    this.mascotDescription,
    this.weeklyScores,
    this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Handle data null dengan fallback ke sample
    final now = DateTime.now();
    final fallbackWeeklyScores = [89, 76, 0, 65, 0, 95, 88];
    final fallbackDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final sleepState = isSleeping ?? false;
    final sleepStartTime = startTime ?? now.subtract(const Duration(hours: 7));
    final displayedSleepScore = sleepScore ?? 88;
    final displayedMascot = mascot ?? '😴';
    final displayedMascotName = mascotName ?? 'Sleepy Sloth';
    final displayedMascotDesc =
        mascotDescription ?? 'Kamu tidur nyenyak semalam!';
    final displayedScores = weeklyScores ?? fallbackWeeklyScores;
    final labels = dayLabels ?? fallbackDayLabels;

    final todayIndex = now.weekday % 7;

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
              Center(
                child: Column(
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
                      child: Text(
                        sleepState ? '😴' : '😊',
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Tombol Tidur",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sleepState)
                      Text(
                        "Mulai: ${sleepStartTime.hour}:${sleepStartTime.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: TuruColors.textColor2),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      sleepState ? "Sedang Tidur" : "Klik tombol untuk memulai",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tips Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/tips');
                },
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
              Text(
                startTime != null
                    ? "Mulai: ${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}:${startTime!.second.toString().padLeft(2, '0')}"
                    : "Mulai: -",
                style: const TextStyle(color: TuruColors.textColor2),
              ),
              Text(
                startTime != null
                    ? "Selesai: ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}"
                    : "Selesai: -",
                style: const TextStyle(color: TuruColors.textColor2),
              ),
              const Text(
                "13 j 20m", // Placeholder for duration calculation
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 48),
              const _SectionTitle(title: "Skor Tidur"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(displayedMascot, style: const TextStyle(fontSize: 72)),
                  const SizedBox(width: 16),
                  Text(
                    displayedSleepScore.toString(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                displayedMascotName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  displayedMascotDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TuruColors.textColor2),
                ),
              ),

              const SizedBox(height: 48),
              const _SectionTitle(title: "Statistik Tidur Mingguan"),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.6,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            return Text(
                              labels[index],
                              style: TextStyle(
                                color:
                                    index == todayIndex
                                        ? TuruColors.pink
                                        : Colors.grey[400],
                                fontWeight:
                                    index == todayIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: List.generate(displayedScores.length, (index) {
                      final score = displayedScores[index];
                      final isToday = index == todayIndex;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: score == 0 ? 3 : score.toDouble(),
                            width: 16,
                            color: isToday ? TuruColors.pink : Colors.blue[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      );
                    }),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
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
                  Icon(Icons.post_add, size: 28),
                  SizedBox(height: 6),
                  Text(
                    "Tambah",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      ),
                  ),
                ],
              ),
            ),
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
