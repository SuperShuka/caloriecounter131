import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/log_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_logs_service.dart';
import '../services/logs_notifier.dart';
import 'food_edit_widget.dart';

class LogList extends ConsumerWidget {
  final List<LogItem> logs;

  const LogList({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logs',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Dismissible(
                key: Key(log.timestamp.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onDismissed: (direction) {
                  // Remove the log from the state
                  ref.read(logsProvider.notifier).state =
                      logs.where((item) => item != log).toList();
                  ref.read(firebaseLogsServiceProvider).deleteLogItem(log);
                },
                child: GestureDetector(
                  onTap: () {
                    if (log.type == LogItemType.meal) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) =>
                                FoodEditWidget(logItem: log)),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Macros
                                    if (log.macros != null)
                                      Row(
                                        children: log.macros!
                                            .map((macro) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 10),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        macro.icon,
                                                        style: const TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${macro.value}g',
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        color: log.calories >= 0
                                            ? Colors.orange
                                            : Colors.red,
                                      ),
                                      Text(
                                        '${log.calories}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: log.calories >= 0
                                              ? Colors.orange
                                              : Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    DateFormat('HH:mm').format(log.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
