import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/air_countdown_text.dart';
import 'package:kazumi/bean/widget/tonal_card.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/utils/air_schedule.dart';

/// 详情页的放送信息卡：放送日期、每周更新时间与下一话倒计时。
class BangumiAirInfoCard extends StatelessWidget {
  const BangumiAirInfoCard({super.key, required this.bangumiItem});

  final BangumiItem bangumiItem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasDate = bangumiItem.airDate.isNotEmpty;
    final hasTime = bangumiItem.airTime.isNotEmpty;
    final next = hasDate
        ? nextAiringDate(
            airWeekday: bangumiItem.airWeekday,
            airTime: bangumiItem.airTime,
          )
        : null;

    return TonalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text('放送信息', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          _AirInfoRow(
            label: '放送开始',
            value: hasDate ? bangumiItem.airDate : '未知',
          ),
          _AirInfoRow(
            label: '更新星期',
            value: hasDate ? '每${airWeekdayName(bangumiItem.airWeekday)}' : '未知',
          ),
          if (hasTime) _AirInfoRow(label: '更新时间', value: bangumiItem.airTime),
          if (bangumiItem.totalEpisodes > 0)
            _AirInfoRow(label: '话数', value: '全 ${bangumiItem.totalEpisodes} 话'),
          if (next != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '下一话',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${next.month} 月 ${next.day} 日 ${airWeekdayName(next.weekday)}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}',
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AirCountdownText(
                    target: next,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AirInfoRow extends StatelessWidget {
  const _AirInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
