import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:turu_mobile/pages/listview_history.dart';
import '../main.dart'; // Assuming TuruColors is defined here

class BerandaPage extends StatefulWidget {
  final bool? initialSleeping;
  final DateTime? initialStartTime;
  final int? sleepScore;
  final String? mascot;
  final String? mascotName;
  final String? mascotDescription;
  final List<int>? weeklyScores;
  final List<String>? dayLabels;

  const BerandaPage({
    super.key,
    this.initialSleeping,
    this.initialStartTime,
    this.sleepScore,
    this.mascot,
    this.mascotName,
    this.mascotDescription,
    this.weeklyScores,
    this.dayLabels,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  bool isSleeping = false;
  DateTime? sleepStartTime;
  Timer? sleepTimer;
  Duration sleepDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    isSleeping = widget.initialSleeping ?? false;
    sleepStartTime = widget.initialStartTime;

    if (isSleeping && sleepStartTime != null) {
      _startSleepTimer();
    }
  }

  @override
  void dispose() {
    sleepTimer?.cancel();
    super.dispose();
  }

  void _startSleepTimer() {
    sleepTimer?.cancel(); // make sure no previous timer
    sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (sleepStartTime != null) {
          sleepDuration = DateTime.now().difference(sleepStartTime!);
        }
      });
    });
  }

  void _toggleSleep() {
    setState(() {
      if (isSleeping) {
        // Kalau sedang tidur, tekan -> bangun
        isSleeping = false;
        sleepTimer?.cancel();
      } else {
        // Kalau tidak tidur, tekan -> mulai tidur
        isSleeping = true;
        sleepStartTime = DateTime.now();
        sleepDuration = Duration.zero;
        _startSleepTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours}j ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fallbackWeeklyScores = [89, 76, 0, 65, 0, 95, 88];
    final fallbackDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final displayedSleepScore = widget.sleepScore ?? 88;
    final displayedMascot = widget.mascot ?? '😴';
    final displayedMascotName = widget.mascotName ?? 'Sleepy Sloth';
    final displayedMascotDesc =
        widget.mascotDescription ?? 'Kamu tidur nyenyak semalam!';
    final displayedScores = widget.weeklyScores ?? fallbackWeeklyScores;
    final labels = widget.dayLabels ?? fallbackDayLabels;
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
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Tombol Tidur
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _toggleSleep,
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
                        isSleeping ? '😴' : '😊',
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
                    if (sleepStartTime != null)
                      Text(
                        "Mulai: ${sleepStartTime!.hour}:${sleepStartTime!.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: TuruColors.textColor2),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      isSleeping ? "Sedang Tidur" : "Klik tombol untuk memulai",
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.nightlight_round, size: 20),
                label: const Text("Tips Tidur", style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 48),

              const _SectionTitle(title: "Data Tidur"),
              const SizedBox(height: 8),

              Text(
                sleepStartTime != null
                    ? "Mulai: ${sleepStartTime!.hour}:${sleepStartTime!.minute.toString().padLeft(2, '0')}:${sleepStartTime!.second.toString().padLeft(2, '0')}"
                    : "Mulai: -",
                style: const TextStyle(color: TuruColors.textColor2),
              ),
              Text(
                isSleeping
                    ? "Selesai: -"
                    : sleepStartTime != null
                        ? "Selesai: ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}"
                        : "Selesai: -",
                style: const TextStyle(color: TuruColors.textColor2),
              ),
              Text(
                sleepStartTime != null
                    ? _formatDuration(sleepDuration)
                    : "Durasi: -",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
                                color: index == todayIndex
                                    ? TuruColors.pink
                                    : Colors.grey[400],
                                fontWeight: index == todayIndex
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
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SleepHistoryPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuruColors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Lihat Riwayat Tidur",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),

        // Floating Action Button
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
