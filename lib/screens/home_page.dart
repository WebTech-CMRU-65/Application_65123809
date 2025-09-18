import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  final TextEditingController _taskController = TextEditingController();

  // Firestore reference
  CollectionReference get taskRef => FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .collection("tasks");

  @override
  Widget build(BuildContext context) {
    // normalize วัน
    final startOfDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final endOfDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      23,
      59,
      59,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  // 📅 Calendar
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: focusedDay,
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF60D6CB),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF0FB5AE),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A3D62),
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color(0xFF0A3D62),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color(0xFF0A3D62),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ ToDo List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: taskRef
                          .where(
                            "date",
                            isGreaterThanOrEqualTo: Timestamp.fromDate(
                              startOfDay,
                            ),
                          )
                          .where(
                            "date",
                            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
                          )
                          .orderBy("date")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text("ยังไม่มีงานในวันนี้"),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Colors.grey),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final done = data["done"] ?? false;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: done,
                                  onChanged: (value) {
                                    doc.reference.update({"done": value});
                                  },
                                ),
                                title: Text(
                                  data["task"] ?? "-",
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: done ? Colors.grey : Colors.black,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => doc.reference.delete(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ➕ Add Task
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _taskController,
                            decoration: InputDecoration(
                              hintText:
                                  "เพิ่มงานใหม่สำหรับ ${selectedDay.toLocal().toString().split(' ')[0]}",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            backgroundColor: const Color(0xFF0FB5AE),
                          ),
                          onPressed: () async {
                            if (_taskController.text.isNotEmpty) {
                              await taskRef.add({
                                "task": _taskController.text,
                                "createdAt": FieldValue.serverTimestamp(),
                                "date": Timestamp.fromDate(startOfDay),
                                "done": false,
                              });
                              _taskController.clear();
                            }
                          },
                          child: const Text(
                            "เพิ่ม",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
