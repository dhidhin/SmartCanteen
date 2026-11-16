import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/order_status_badge.dart';
import '../auth/login_screen.dart';
import 'kelola_menu_screen.dart';

class PenjualHomeScreen extends StatefulWidget {
  const PenjualHomeScreen({super.key});

  @override
  State<PenjualHomeScreen> createState() => _PenjualHomeScreenState();
}

class _PenjualHomeScreenState extends State<PenjualHomeScreen> {
  String _filterStatus = 'Semua';

  final List<String> _statusFilters = [
    'Semua',
    AppConstants.statusMenunggu,
    AppConstants.statusDimasak,
    AppConstants.statusSiapDiambil,
    AppConstants.statusSelesai,
  ];

  Future<void> _showEditStandDialog(BuildContext context, AppAuthProvider auth) async {
    final standCtrl = TextEditingController(text: auth.currentUser?.namaStand);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Atur Nama Stand'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nama stand / kantin Anda (contoh: Kantin Bu Siti, Stand Es Segar):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: standCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Stand',
                hintText: 'Kantin Bu Siti',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = standCtrl.text.trim();
              if (newName.isNotEmpty) {
                await auth.updateNamaStand(newName);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nama stand diperbarui menjadi "$newName"'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Penjual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Kelola Menu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KelolaMenuScreen()),
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit_stand',
                child: Row(
                  children: [
                    Icon(Icons.storefront, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Ubah Nama Stand'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Keluar'),
                  ],
                ),
              ),
            ],
            onSelected: (val) async {
              if (val == 'edit_stand') {
                _showEditStandDialog(context, auth);
              } else if (val == 'logout') {
                final navigator = Navigator.of(context);
                await auth.logout();
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info penjual
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.currentUser?.namaStand.isNotEmpty == true
                            ? '🏪 ${auth.currentUser!.namaStand}'
                            : 'Selamat datang, ${auth.currentUser?.nama ?? 'Penjual'}! 👨‍🍳',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.currentUser?.namaStand.isNotEmpty == true
                            ? 'Pengelola: ${auth.currentUser?.nama ?? 'Penjual'}'
                            : 'Ketuk pensil untuk atur nama stand kamu',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  tooltip: 'Ubah Nama Stand',
                  onPressed: () => _showEditStandDialog(context, auth),
                ),
              ],
            ),
          ),
          // Filter status
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _statusFilters.map((s) {
                  final selected = _filterStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) => setState(() => _filterStatus = s),
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Banner klaim / hapus pesanan tak bertuan (jika ada data uji coba lama)
          StreamBuilder<List<OrderModel>>(
            stream: OrderService().getUnassignedOrdersStream(),
            builder: (context, unassignedSnap) {
              final unassigned = unassignedSnap.data ?? [];
              if (unassigned.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${unassigned.length} pesanan lama belum terikat stand.',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hubungkan ke stand "${auth.currentUser?.namaStand.isNotEmpty == true ? auth.currentUser!.namaStand : "Stand Saya"}" atau bersihkan data.',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          icon: const Icon(Icons.link, size: 14),
                          label: const Text('Klaim ke Stand Ini'),
                          onPressed: () async {
                            final uid = auth.currentUser?.uid ?? '';
                            final stand = auth.currentUser?.namaStand ?? 'Kantin';
                            for (final o in unassigned) {
                              await OrderService().assignOrderToPenjual(
                                orderId: o.orderId,
                                penjualId: uid,
                                namaStand: stand,
                              );
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${unassigned.length} pesanan berhasil diklaim ke stand "$stand"!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 14),
                          label: const Text('Hapus'),
                          onPressed: () async {
                            for (final o in unassigned) {
                              await OrderService().deleteOrder(o.orderId);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Pesanan lama berhasil dihapus.'),
                                  backgroundColor: AppColors.textSecondary,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // Daftar pesanan khusus pedagang ini
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: OrderService().getPenjualOrdersStream(
                penjualId: auth.currentUser?.uid ?? '',
                namaStand: auth.currentUser?.namaStand ?? '',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var orders = snapshot.data ?? [];
                if (_filterStatus != 'Semua') {
                  orders = orders
                      .where((o) => o.status == _filterStatus)
                      .toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 72, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == 'Semua'
                              ? 'Belum ada pesanan masuk'
                              : 'Tidak ada pesanan berstatus "$_filterStatus"',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _PesananCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PesananCard extends StatefulWidget {
  final OrderModel order;

  const _PesananCard({required this.order});

  @override
  State<_PesananCard> createState() => _PesananCardState();
}

class _PesananCardState extends State<_PesananCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);
    try {
      await OrderService().updateOrderStatus(
        orderId: widget.order.orderId,
        newStatus: widget.order.nextStatus,
        siswaFcmToken: widget.order.siswaFcmToken,
        nomorAntrean: widget.order.nomorAntrean,
        namaStand: widget.order.namaStand,
        penjualId: widget.order.penjualId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status pesanan #${widget.order.nomorAntrean} diubah ke "${widget.order.nextStatus}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Nomor Antrean, Stand, dan Status Pesanan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${order.nomorAntrean}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (order.namaStand.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront,
                                    size: 12, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    order.namaStand,
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            // Baris 2: Kotak Khusus Info Siswa Pemesan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.namaSiswa.isNotEmpty
                              ? order.namaSiswa
                              : 'Nama Siswa Tidak Diketahui',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          order.kelasSiswa.isNotEmpty
                              ? 'Kelas: ${order.kelasSiswa}'
                              : 'Siswa',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.qty}x',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.namaMenu),
                            if (item.catatan.isNotEmpty)
                              Text(
                                '📝 ${item.catatan}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💵 Bayar di Tempat (COD)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Total: Rp ${_fmt(order.totalHarga)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (order.canAdvance) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusColor(order.nextStatus),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('▶ ${order.nextStatus}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Dimasak':
        return AppColors.statusDimasak;
      case 'Siap Diambil':
        return AppColors.statusSiapDiambil;
      case 'Selesai':
        return AppColors.statusSelesai;
      default:
        return AppColors.primary;
    }
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
