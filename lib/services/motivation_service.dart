import '../core/data/motivational_messages.dart';

class MotivationService {
  const MotivationService();

  String getMessageForDate(DateTime date) {
    final daysSinceEpoch = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(2000)).inDays;
    final index = daysSinceEpoch.abs() % motivationalMessages.length;
    return motivationalMessages[index];
  }

  int get totalMessages => motivationalMessages.length;
}
