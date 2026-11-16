import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_model.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';

class MenuCardSiswa extends StatelessWidget {
  final MenuModel menu;

  const MenuCardSiswa({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qtyInCart = cart.getQty(menu.menuId);
    final canOrder = menu.isOrderable;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gambar menu
          Expanded(
            child: Stack(
              children: [
                menu.gambarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: menu.gambarUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.divider,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => _DefaultImage(),
                      )
                    : _DefaultImage(),
                // Badge stok habis
                if (!canOrder)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            menu.stok == 0 ? 'Stok Habis' : 'Tidak Tersedia',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Kategori badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      menu.kategori,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info menu
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.namaMenu,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (menu.namaStand.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            menu.namaStand,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_fmt(menu.harga)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sisa: ${menu.stok}',
                  style: TextStyle(
                    color: menu.stok > 5
                        ? AppColors.textSecondary
                        : menu.stok > 0
                            ? AppColors.warning
                            : AppColors.error,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                // Tombol tambah/kurang
                if (canOrder)
                  qtyInCart == 0
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.read<CartProvider>().addItem(
                              menuId: menu.menuId,
                              namaMenu: menu.namaMenu,
                              harga: menu.harga,
                              penjualId: menu.penjualId,
                              namaStand: menu.namaStand,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('+ Tambah'),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SmallButton(
                              icon: Icons.remove,
                              onTap: () => context
                                  .read<CartProvider>()
                                  .decreaseQty(menu.menuId),
                            ),
                            Text(
                              '$qtyInCart',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            _SmallButton(
                              icon: Icons.add,
                              onTap: () =>
                                  context.read<CartProvider>().addItem(
                                    menuId: menu.menuId,
                                    namaMenu: menu.namaMenu,
                                    harga: menu.harga,
                                    penjualId: menu.penjualId,
                                    namaStand: menu.namaStand,
                                  ),
                            ),
                          ],
                        )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Tidak Tersedia'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _DefaultImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.fastfood, size: 36, color: AppColors.primary),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
