import 'dart:async';

import 'package:flutter/material.dart';

/// 下一话更新的倒计时文本，30 秒刷新一次。
class AirCountdownText extends StatefulWidget {
  const AirCountdownText({super.key, required this.target, this.style});

  final DateTime target;
  final TextStyle? style;

  @override
  State<AirCountdownText> createState() => _AirCountdownTextState();
}

class _AirCountdownTextState extends State<AirCountdownText> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format(Duration left) {
    if (left.isNegative) return '已更新';
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    if (days > 0) return '还有 $days 天 $hours 小时';
    if (hours > 0) return '还有 $hours 小时 $minutes 分';
    return '还有 $minutes 分';
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.target.difference(DateTime.now());
    return Text(
      _format(left),
      style:
          widget.style ??
          Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
