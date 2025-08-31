import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock history data (replace with your real data later)
    final items = List.generate(
      12,
      (i) => _HistoryItem(
        time: DateTime.now().subtract(Duration(hours: i * 7 + 2)),
        grams: ((i % 3) + 1) * 50, // 50g, 100g, 150g
        note: i % 4 == 0 ? "Scheduled" : "Manual",
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding History'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.history)),
            title: Text('${it.grams}g • ${it.note}'),
            subtitle: Text(_formatDateTime(it.time)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Placeholder tap action
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fed ${it.grams}g (${it.note})')),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // e.g. "Sun, 25 Aug 2025 • 14:05"
    final w = _weekday[dt.weekday]!;
    final m = _month[dt.month]!;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$w, ${dt.day} $m ${dt.year} • $hh:$mm';
  }
}

class _HistoryItem {
  final DateTime time;
  final int grams;
  final String note;
  _HistoryItem({required this.time, required this.grams, required this.note});
}

const _weekday = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

const _month = {
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};
