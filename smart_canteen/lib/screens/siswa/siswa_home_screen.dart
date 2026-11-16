import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../models/menu_model.dart';
import '../../widgets/menu_card_siswa.dart';
import '../../widgets/badge_cart_icon.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'pesanan_saya_screen.dart';

class SiswaHomeScreen extends StatefulWidget {
  const SiswaHomeScreen({super.key});

  @override
  State<SiswaHomeScreen> createState() => _SiswaHomeScreenState();
}

class _SiswaHomeScreenState extends State<SiswaHomeScreen> {
  String _selectedKategori = 'Semua';
  String _selectedStand = 'Semua Stand';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Canteen'),
        actions: [
          BadgeCartIcon(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Pesanan Saya',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PesananSayaScreen()),
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
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
              if (val == 'logout') {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header greeting
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.nama.split(' ').first ?? 'Siswa'}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.kelas ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari menu...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // Menu list & Stand Filter
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menus')
                  .orderBy('namaMenu')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allDocs = snapshot.data?.docs ?? [];
                final allMenus = allDocs
                    .map((doc) => MenuModel.fromFirestore(doc))
                    .toList();

                // Daftar semua stand unik dari database
                final uniqueStands = {'Semua Stand', ...allMenus.map((m) =>
                    m.namaStand.isNotEmpty ? m.namaStand : 'Kantin Sekolah')}.toList();

                if (!uniqueStands.contains(_selectedStand)) {
                  _selectedStand = 'Semua Stand';
                }

                var filteredMenus = List<MenuModel>.from(allMenus);

                // Filter by stand
                if (_selectedStand != 'Semua Stand') {
                  filteredMenus = filteredMenus.where((m) {
                    final stand = m.namaStand.isNotEmpty ? m.namaStand : 'Kantin Sekolah';
                    return stand == _selectedStand;
                  }).toList();
                }

                // Filter by kategori
                if (_selectedKategori != 'Semua') {
                  filteredMenus = filteredMenus
                      .where((m) => m.kategori == _selectedKategori)
                      .toList();
                }

                // Filter by search (nama menu atau nama stand)
                if (_searchQuery.isNotEmpty) {
                  filteredMenus = filteredMenus
                      .where((m) =>
                          m.namaMenu.toLowerCase().contains(_searchQuery) ||
                          m.namaStand.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                // Kelompokkan menu berdasarkan namaStand
                final Map<String, List<MenuModel>> groupedByStand = {};
                for (final m in filteredMenus) {
                  final stand = m.namaStand.isNotEmpty ? m.namaStand : 'Kantin Sekolah';
                  groupedByStand.putIfAbsent(stand, () => []).add(m);
                }

                return Column(
                  children: [
                    // Filter bar: Stand & Kategori
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Stand Chips (jika ada lebih dari 1 stand)
                          if (uniqueStands.length > 2) ...[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: uniqueStands.map((stand) {
                                  final isSelected = _selectedStand == stand;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon(
                                        Icons.storefront,
                                        size: 16,
                                        color: isSelected ? Colors.white : AppColors.primary,
                                      ),
                                      label: Text(stand),
                                      selected: isSelected,
                                      onSelected: (_) => setState(() => _selectedStand = stand),
                                      selectedColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          // 2. Kategori Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: AppConstants.kategoriMenu.map((kat) {
                                final selected = _selectedKategori == kat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(kat),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _selectedKategori = kat),
                                    selectedColor: AppColors.secondary,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Menu list grouped by Stand
                    Expanded(
                      child: filteredMenus.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64, color: AppColors.textSecondary),
                                  SizedBox(height: 12),
                                  Text(
                                    'Menu tidak ditemukan',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: groupedByStand.entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Stand / Pedagang
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12, top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.storefront,
                                                color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${entry.value.length} Menu',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Grid Menu untuk stand ini
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.72,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: entry.value.length,
                                      itemBuilder: (_, i) => MenuCardSiswa(menu: entry.value[i]),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
