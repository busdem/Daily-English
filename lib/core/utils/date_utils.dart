DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime today() => dateOnly(DateTime.now());

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isYesterday(DateTime date, DateTime reference) {
  final yesterday = dateOnly(reference).subtract(const Duration(days: 1));
  return isSameDay(date, yesterday);
}
