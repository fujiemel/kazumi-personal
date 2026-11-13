const _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String airWeekdayName(int weekday) => _weekdayNames[(weekday - 1) % 7];

/// 计算下一次放送时间；没有更新时间时返回 null。
DateTime? nextAiringDate({
  required int airWeekday,
  required String airTime,
}) {
  if (airTime.isEmpty) return null;
  if (airWeekday < DateTime.monday || airWeekday > DateTime.sunday) {
    return null;
  }
  final parts = airTime.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day, hour, minute);
  final delta = (airWeekday - target.weekday) % 7;
  target = target.add(Duration(days: delta));
  if (!target.isAfter(now)) target = target.add(const Duration(days: 7));
  return target;
}

/// 追番卡片上的更新提示，例如「周一 22:00 更新」「明天 22:00 更新」。
/// 对开播已久的番剧返回 null，避免把旧番误标成正在更新。
String? nextAiringLabel({
  required String airDate,
  required int airWeekday,
  required String airTime,
}) {
  if (airDate.isEmpty) return null;
  final start = DateTime.tryParse(airDate);
  if (start == null) return null;
  final now = DateTime.now();
  if (now.difference(start).inDays > 540) return null;

  if (airTime.isEmpty) return '每${airWeekdayName(airWeekday)} 更新';

  final next = nextAiringDate(airWeekday: airWeekday, airTime: airTime);
  if (next == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(next.year, next.month, next.day);
  final days = target.difference(today).inDays;
  if (days == 0) return '今天 $airTime 更新';
  if (days == 1) return '明天 $airTime 更新';
  return '${airWeekdayName(next.weekday)} $airTime 更新';
}
