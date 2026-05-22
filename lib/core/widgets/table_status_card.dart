import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../models/dining_table.dart';

/// Visual card for a dining table showing name, number, seats, and availability.
class TableStatusCard extends StatelessWidget {
  const TableStatusCard({
    super.key,
    required this.table,
    this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final DiningTable table;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final occupied = table.isOccupied;
    final statusColor = occupied ? AppTheme.warning : AppTheme.accent;
    final borderColor = occupied
        ? AppTheme.warning.withValues(alpha: 0.45)
        : AppTheme.accent.withValues(alpha: 0.35);

    return Card(
      elevation: occupied ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: borderColor, width: occupied ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.displayName,
                          style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${table.tableNumber}',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(occupied: occupied, compact: compact),
                ],
              ),
              SizedBox(height: compact ? 8 : 10),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      table.zoneLabel,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 8),
              Row(
                children: [
                  Icon(
                    occupied ? Icons.event_seat : Icons.chair_alt_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    table.seatsLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ],
              ),
              if (!compact && occupied && table.orderNumber != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Order ${table.orderNumber}${table.orderStatus != null ? ' · ${table.orderStatus}' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.occupied, required this.compact});

  final bool occupied;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = occupied ? AppTheme.warning : AppTheme.accent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(occupied ? Icons.person_rounded : Icons.check_circle_outline_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            occupied ? 'Occupied' : 'Available',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: compact ? 10 : 11),
          ),
        ],
      ),
    );
  }
}
