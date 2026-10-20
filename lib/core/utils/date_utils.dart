DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// Calendar-day arithmetic; DateTime.add(Duration(days: n)) can land on the
// wrong day across a DST change.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

String toDateString(DateTime date) {
  final d = dateOnly(date);
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-$month-$day';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isYesterday(DateTime date, DateTime reference) =>
    isSameDay(date, addDays(reference, -1));
