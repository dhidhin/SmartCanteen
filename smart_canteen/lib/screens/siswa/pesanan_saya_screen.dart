import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/order_status_badge.dart';

class PesananSayaScreen extends StatelessWidget {
  const PesananSayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final siswaId = auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getSiswaOrdersStream(siswaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 80, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${order.nomorAntrean}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (order.namaStand.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          order.namaStand,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('${item.qty}x ',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      Expanded(child: Text(item.namaMenu)),
                      Text(
                        'Rp ${_fmt(item.harga * item.qty)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${_fmt(order.totalHarga)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                const Text(
                  '💵 Bayar di Tempat',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            if (order.status == 'Siap Diambil') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.namaStand.isNotEmpty
                            ? 'Pesanan siap! Silakan ambil di ${order.namaStand}.'
                            : 'Pesananmu siap! Silakan ambil di kantin.',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
