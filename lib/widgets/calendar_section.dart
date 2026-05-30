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

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        children: [
          _buildMonthHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCalendar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(focusedMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                focusedMonth = DateTime(
                  focusedMonth.year,
                  focusedMonth.month - 1,
                );
              });
            },
            icon: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                focusedMonth = DateTime(
                  focusedMonth.year,
                  focusedMonth.month + 1,
                );
              });
            },
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);

    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    int startWeekday = firstDayOfMonth.weekday;

    // Sunday = 0
    startWeekday = startWeekday % 7;

    final List<Widget> cells = [];

    const weekdays = [
      'Su',
      'Mo',
      'Tu',
      'We',
      'Th',
      'Fr',
      'Sa',
    ];

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

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) => cells[index],
        ));
  }
}
