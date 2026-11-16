import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(status);
    final icon = _iconForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'Menunggu':
        return AppColors.statusMenunggu;
      case 'Dimasak':
        return AppColors.statusDimasak;
      case 'Siap Diambil':
        return AppColors.statusSiapDiambil;
      case 'Selesai':
        return AppColors.statusSelesai;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'Menunggu':
        return Icons.access_time;
      case 'Dimasak':
        return Icons.local_fire_department;
      case 'Siap Diambil':
        return Icons.check_circle;
      case 'Selesai':
        return Icons.done_all;
      default:
        return Icons.info_outline;
    }
  }
}
