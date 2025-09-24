import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  final HabitService _habitService = HabitService();
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitDescriptionController =
      TextEditingController();
  String _selectedEmoji = '💧';

  final List<String> _emojis = ['💧', '🏃', '📚', '🍎', '😴', '🧘', '💪', '🎯'];

  @override
  void initState() {
    super.initState();
    _initializeDefaultHabits();
  }

  Future<void> _initializeDefaultHabits() async {
    // Check if habits already exist
    final habitsStream = _habitService.getHabits();
    habitsStream.first.then((habits) {
      if (habits.isEmpty) {
        // Create default habits
        _createDefaultHabits();
      }
    });
  }

  Future<void> _createDefaultHabits() async {
    final defaultHabits = [
      Habit(
        id: '',
        name: 'ดื่มน้ำ',
        emoji: '💧',
        description: 'ดื่มน้ำให้เพียงพอในแต่ละวัน (8 แก้ว)',
        createdAt: DateTime.now(),
      ),
      Habit(
        id: '',
        name: 'ออกกำลังกาย',
        emoji: '🏃',
        description: 'ออกกำลังกายในแต่ละวัน (1 ครั้ง)',
        createdAt: DateTime.now(),
      ),
      Habit(
        id: '',
        name: 'อ่านหนังสือ',
        emoji: '📚',
        description: 'อ่านหนังสือในแต่ละวัน (1 ครั้ง)',
        createdAt: DateTime.now(),
      ),
    ];

    for (final habit in defaultHabits) {
      await _habitService.createHabit(habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: const Color(0xFF0FB5AE),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0FB5AE), Color(0xFF60D6CB), Color(0xFFB3F0EA)],
          ),
        ),
        child: StreamBuilder<List<Habit>>(
          stream: _habitService.getHabits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }

            final habits = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Today's Habits Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D5F2), // Light purple
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กิจวัตรวันนี้ (${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year})',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A3D62),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (habits.isEmpty)
                          const Center(
                            child: Text(
                              'ยังไม่มีกิจวัตร\nกดปุ่ม + เพื่อเพิ่มกิจวัตรใหม่',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...habits.map((habit) => _buildTodayHabitItem(habit)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Statistics Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D5F2), // Light purple
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สถิติ 7 วันล่าสุด',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A3D62),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (habits.isEmpty)
                          const Center(
                            child: Text(
                              'ยังไม่มีข้อมูลสถิติ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...habits.map((habit) => _buildStatisticItem(habit)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Add Habit Button
                  FloatingActionButton.extended(
                    onPressed: () => _showAddHabitDialog(),
                    backgroundColor: const Color(0xFF0FB5AE),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มกิจวัตร'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodayHabitItem(Habit habit) {
    final today = DateTime.now();
    final todayStr = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    return FutureBuilder<Map<String, int>>(
      future: _habitService.getHabitValuesLast7Days(habit.id),
      builder: (context, snapshot) {
        final valueData = snapshot.data ?? {};
        final todayValue = valueData[todayStr] ?? 0;
        final targetValue = _getTargetValue(habit.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getHabitColor(habit.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),

              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A3D62),
                      ),
                    ),
                    Text(
                      '$todayValue/$targetValue',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Control buttons
              Row(
                children: [
                  IconButton(
                    onPressed: todayValue > 0
                        ? () async {
                            try {
                              await _habitService.recordHabitCompletion(
                                habit.id,
                                today,
                                completed: true,
                                value: todayValue - 1,
                              );
                              setState(() {});
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('เกิดข้อผิดพลาด: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: todayValue > 0
                          ? Colors.red[100]
                          : Colors.grey[200],
                      foregroundColor: todayValue > 0
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$todayValue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      try {
                        await _habitService.recordHabitCompletion(
                          habit.id,
                          today,
                          completed: true,
                          value: todayValue + 1,
                        );
                        setState(() {});
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เกิดข้อผิดพลาด: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0FB5AE),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticItem(Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getHabitColor(habit.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Text(
                habit.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A3D62),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 60, child: _buildPercentageChart(habit)),
        ],
      ),
    );
  }

  Widget _buildPercentageChart(Habit habit) {
    return FutureBuilder<Map<String, int>>(
      future: _habitService.getHabitValuesLast7Days(habit.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final valueData = snapshot.data ?? {};
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 6));

        // Prepare data for chart
        final List<FlSpot> spots = [];
        final List<String> dayLabels = [];

        for (int i = 0; i < 7; i++) {
          final date = sevenDaysAgo.add(Duration(days: i));
          final dateStr = DateTime(
            date.year,
            date.month,
            date.day,
          ).toIso8601String();
          final value = valueData[dateStr] ?? 0;
          final targetValue = _getTargetValue(habit.name);
          final percentage = targetValue > 0
              ? (value / targetValue * 100).clamp(0, 100)
              : 0;

          spots.add(FlSpot(i.toDouble(), percentage.toDouble()));

          // Day labels
          final dayNames = ['พฤ', 'ศ', 'ส', 'อา', 'จ', 'อ', 'พ'];
          dayLabels.add(dayNames[date.weekday - 1]);
        }

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == 0)
                      return const Text('0%', style: TextStyle(fontSize: 10));
                    if (value == 100)
                      return const Text('100%', style: TextStyle(fontSize: 10));
                    return const Text('');
                  },
                  reservedSize: 25,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < dayLabels.length) {
                      return Text(
                        dayLabels[value.toInt()],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 20,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _getHabitColor(habit.name),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: _getHabitColor(habit.name),
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: _getHabitColor(habit.name).withOpacity(0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final index = touchedSpot.x.toInt();
                    final date = sevenDaysAgo.add(Duration(days: index));
                    final value =
                        valueData[DateTime(
                          date.year,
                          date.month,
                          date.day,
                        ).toIso8601String()] ??
                        0;
                    final targetValue = _getTargetValue(habit.name);
                    final percentage = targetValue > 0
                        ? (value / targetValue * 100).clamp(0, 100)
                        : 0;

                    return LineTooltipItem(
                      '${date.day}/${date.month}\n${percentage.toInt()}%',
                      GoogleFonts.inter(fontSize: 10, color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getHabitColor(String habitName) {
    switch (habitName) {
      case 'ดื่มน้ำ':
        return Colors.blue;
      case 'ออกกำลังกาย':
        return Colors.green;
      case 'อ่านหนังสือ':
        return Colors.orange;
      default:
        return const Color(0xFF0FB5AE);
    }
  }

  int _getTargetValue(String habitName) {
    switch (habitName) {
      case 'ดื่มน้ำ':
        return 8;
      case 'ออกกำลังกาย':
        return 1;
      case 'อ่านหนังสือ':
        return 1;
      default:
        return 1;
    }
  }

  void _showAddHabitDialog() {
    _habitNameController.clear();
    _habitDescriptionController.clear();
    _selectedEmoji = '💧';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มกิจวัตรใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Selection
              Text(
                'เลือกอีโมจิ:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedEmoji == emoji
                            ? const Color(0xFF0FB5AE)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Habit Name
              TextField(
                controller: _habitNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อกิจวัตร',
                  hintText: 'เช่น ดื่มน้ำ, ออกกำลังกาย',
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _habitDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'คำอธิบาย',
                  hintText: 'อธิบายเพิ่มเติมเกี่ยวกับกิจวัตรนี้',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_habitNameController.text.isNotEmpty) {
                final habit = Habit(
                  id: '',
                  name: _habitNameController.text,
                  emoji: _selectedEmoji,
                  description: _habitDescriptionController.text,
                  createdAt: DateTime.now(),
                );
                await _habitService.createHabit(habit);
                Navigator.pop(context);
              }
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }
}
