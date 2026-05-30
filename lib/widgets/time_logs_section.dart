import 'package:flutter/material.dart';

class TimeLogsSection extends StatelessWidget {
  const TimeLogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      "Time In",
      "Time Out",
      "Break 1 Out",
      "Break 1 In",
      "Break 2 Out",
      "Break 2 In",
      "Break 3 Out",
      "Break 3 In",
      "Lunch Out",
      "Lunch In",
    ];

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  actions[index],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
