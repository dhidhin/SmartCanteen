import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_success_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrdering = false;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AppAuthProvider>();

    if (cart.isEmpty) return;
    if (auth.currentUser == null) return;

    setState(() => _isOrdering = true);

    try {
      // Ambil FCM token penjual dari Firestore (opsional, tidak membatalkan checkout jika gagal)
      String penjualFcmToken = '';
      try {
        final penjualSnap = await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.rolePenjual)
            .limit(1)
            .get();

        if (penjualSnap.docs.isNotEmpty) {
          penjualFcmToken =
              penjualSnap.docs.first.data()['fcmToken'] as String? ?? '';
        }
      } catch (e) {
        debugPrint('Warning fetching penjual FCM token: $e');
      }

      final antreanList = await OrderService().createOrder(
        siswa: auth.currentUser!,
        cartItems: cart.items.toList(),
        defaultPenjualFcmToken: penjualFcmToken,
      );

      cart.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(antreanList: antreanList),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memesan: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Kosongkan Keranjang?'),
                    content: const Text(
                        'Semua item di keranjang akan dihapus.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal')),
                      TextButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Hapus',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Hapus Semua',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Keranjang masih kosong',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.namaMenu,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (item.namaStand.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '🏪 ${item.namaStand}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () =>
                                        cart.removeItem(item.menuId),
                                  ),
                                ],
                              ),
                              Text(
                                'Rp ${_formatRupiah(item.harga)}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              // Qty control
                              Row(
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove,
                                    onTap: () =>
                                        cart.decreaseQty(item.menuId),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      '${item.qty}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add,
                                    onTap: () => cart.addItem(
                                      menuId: item.menuId,
                                      namaMenu: item.namaMenu,
                                      harga: item.harga,
                                      penjualId: item.penjualId,
                                      namaStand: item.namaStand,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Rp ${_formatRupiah(item.subtotal)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Catatan
                              TextField(
                                decoration: const InputDecoration(
                                  hintText:
                                      'Catatan (opsional, misal: tidak pedas)',
                                  prefixIcon: Icon(Icons.note_alt_outlined,
                                      size: 20),
                                  isDense: true,
                                ),
                                onChanged: (val) =>
                                    cart.updateCatatan(item.menuId, val),
                                controller: TextEditingController(
                                    text: item.catatan)
                                  ..selection = TextSelection.collapsed(
                                      offset: item.catatan.length),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Ringkasan & Tombol Pesan
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cart.itemCount} item',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                          const Text(
                            'Bayar di Tempat (COD)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Rp ${_formatRupiah(cart.totalHarga)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isOrdering ? null : _placeOrder,
                          icon: _isOrdering
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                              _isOrdering ? 'Memproses...' : 'Pesan Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
