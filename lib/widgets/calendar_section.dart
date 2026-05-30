import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarSection extends StatefulWidget {
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime focusedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  // MOCK DATA (replace with backend later)
  final Map<String, List<String>> mockLogs = {
    "2026-05-30": [
      "Time In: 08:01 AM",
      "Break 1 Out: 10:00 AM",
      "Lunch In: 01:00 PM",
    ]
  };

  final Map<String, String> mockNotes = {
    "2026-05-30": "Team meeting at 3PM",
  };

  final Map<String, String> mockHolidays = {
    "2026-05-25": "National Holiday",
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        children: [
          _buildMonthHeader(),

          // =====================
          // CALENDAR
          // =====================
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCalendar(),
            ),
          ),

          const SizedBox(height: 8),

          // =====================
          // BOTTOM PANEL
          // =====================
          Expanded(
            flex: 2,
            child: _buildInfoPanel(),
          ),
        ],
      ),
    );
  }

  // =====================
  // HEADER
  // =====================
  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        DateFormat('MMMM yyyy').format(focusedMonth),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
        ),
      ),
    );
  }

  // =====================
  // CALENDAR
  // =====================
  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);

    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    int startWeekday = firstDayOfMonth.weekday % 7;

    final List<Widget> cells = [];

    const weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    for (final day in weekdays) {
      cells.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(
        focusedMonth.year,
        focusedMonth.month,
        day,
      );

      final isSelected = selectedDate.year == currentDate.year &&
          selectedDate.month == currentDate.month &&
          selectedDate.day == currentDate.day;

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = currentDate;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.orange,
                      width: 2,
                    ),
                  )
                : null,
            child: Center(
              child: Text(
                "$day",
                style: TextStyle(
                  color: isSelected ? Colors.orange : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) => cells[index],
    );
  }

  // =====================
  // BOTTOM INFO PANEL
  // =====================
  Widget _buildInfoPanel() {
    final key = DateFormat('yyyy-MM-dd').format(selectedDate);

    final logs = mockLogs[key] ?? [];
    final note = mockNotes[key];
    final holiday = mockHolidays[key];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selected Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // HOLIDAY
          if (holiday != null)
            Text(
              "🎉 Holiday: $holiday",
              style: const TextStyle(color: Colors.orange),
            ),

          const SizedBox(height: 6),

          // NOTES
          if (note != null)
            Text(
              "📝 Note: $note",
              style: const TextStyle(color: Colors.blueAccent),
            ),

          const SizedBox(height: 10),

          // LOGS
          const Text(
            "📌 Time Logs:",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      "No logs for this date",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        logs[index],
                        style: const TextStyle(color: Colors.white70),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
