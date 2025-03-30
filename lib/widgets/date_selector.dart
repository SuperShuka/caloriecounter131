import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<String> weekdays;
  final Function(DateTime) onDateSelected;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.weekdays,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final date = selectedDate.subtract(Duration(days: selectedDate.weekday - index));
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: date.day == selectedDate.day
                    ? Colors.green
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      color: date.day == selectedDate.day
                          ? Colors.white
                          : Colors.black54,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: date.day == selectedDate.day
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}