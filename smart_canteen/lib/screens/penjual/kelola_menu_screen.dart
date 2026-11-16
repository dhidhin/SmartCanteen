import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/menu_service.dart';
import '../../utils/app_colors.dart';
import 'tambah_edit_menu_screen.dart';

class KelolaMenuScreen extends StatelessWidget {
  const KelolaMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const TambahEditMenuScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<MenuModel>>(
        stream: MenuService().getMenuStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final auth = context.watch<AppAuthProvider>();
          final currentUid = auth.currentUser?.uid ?? '';
          final currentStand = auth.currentUser?.namaStand.isNotEmpty == true
              ? auth.currentUser!.namaStand
              : (auth.currentUser?.nama ?? 'Kantin Saya');
          final allMenus = snapshot.data ?? [];

          // 1. Menu milik stand ini (baik yang sudah terikat UID maupun yang memiliki nama stand yang cocok)
          final myMenus = allMenus.where((m) {
            if (currentUid.isNotEmpty && m.penjualId == currentUid) return true;
            if (m.penjualId.isEmpty &&
                currentStand.isNotEmpty &&
                m.namaStand.trim().toLowerCase() == currentStand.trim().toLowerCase()) {
              // Otomatis update penjualId di background agar permanen
              MenuService().assignMenuToPenjual(
                menuId: m.menuId,
                penjualId: currentUid,
                namaStand: currentStand,
              );
              return true;
            }
            return false;
          }).toList();

          // 2. Menu lama yang belum memiliki penjualId & belum memiliki nama stand spesifik
          final unassignedMenus = allMenus.where((m) {
            return m.penjualId.isEmpty &&
                (m.namaStand.isEmpty ||
                    m.namaStand == 'Kantin' ||
                    m.namaStand == 'Kantin Sekolah');
          }).toList();

          if (myMenus.isEmpty && unassignedMenus.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.restaurant_menu,
                        size: 72, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada menu di stand "$currentStand"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tekan tombol + Tambah Menu di bawah untuk menambahkan makanan/minuman ke stand ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by kategori
          final grouped = <String, List<MenuModel>>{};
          for (final m in myMenus) {
            grouped.putIfAbsent(m.kategori, () => []).add(m);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner klaim menu lama jika ada
              if (unassignedMenus.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ditemukan ${unassignedMenus.length} produk menu lama tanpa stand.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Produk ini dibuat sebelum sistem multi-pedagang. Ingin menghubungkan semua produk ini ke stand "$currentStand"?',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Klaim ke Stand Ini', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          for (final m in unassignedMenus) {
                            await MenuService().assignMenuToPenjual(
                              menuId: m.menuId,
                              penjualId: currentUid,
                              namaStand: currentStand,
                            );
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${unassignedMenus.length} menu berhasil dihubungkan ke stand "$currentStand"!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // Info stand saat ini
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stand: $currentStand',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${myMenus.length} Menu',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar menu per kategori
              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ...entry.value
                        .map((menu) => _MenuListTile(menu: menu)),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _MenuListTile extends StatelessWidget {
  final MenuModel menu;

  const _MenuListTile({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: menu.gambarUrl.isNotEmpty
              ? Image.network(
                  menu.gambarUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _DefaultFoodIcon(),
                )
              : _DefaultFoodIcon(),
        ),
        title: Text(
          menu.namaMenu,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rp ${_fmt(menu.harga)}',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
            Text(
              'Stok: ${menu.stok}',
              style: TextStyle(
                color:
                    menu.stok > 0 ? AppColors.textSecondary : AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle availability
            Switch(
              value: menu.isAvailable,
              activeThumbColor: AppColors.success,
              onChanged: (val) =>
                  MenuService().toggleAvailability(menu.menuId, val),
            ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TambahEditMenuScreen(menu: menu)),
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, menu),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MenuModel menu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Menu?'),
        content: Text('Hapus "${menu.namaMenu}" dari daftar menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await MenuService().deleteMenu(menu.menuId);
    }
  }

  String _fmt(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _DefaultFoodIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood, color: AppColors.primary),
    );
  }
}
