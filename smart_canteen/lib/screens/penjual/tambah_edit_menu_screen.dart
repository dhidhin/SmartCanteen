import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/menu_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class TambahEditMenuScreen extends StatefulWidget {
  final MenuModel? menu;

  const TambahEditMenuScreen({super.key, this.menu});

  @override
  State<TambahEditMenuScreen> createState() => _TambahEditMenuScreenState();
}

class _TambahEditMenuScreenState extends State<TambahEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();
  final _gambarCtrl = TextEditingController();
  final _standCtrl = TextEditingController();
  String _selectedKategori = AppConstants.kategoriMenu[1]; // Makanan Berat
  bool _isAvailable = true;
  bool _isSaving = false;

  bool get _isEditing => widget.menu != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final m = widget.menu!;
      _namaCtrl.text = m.namaMenu;
      _hargaCtrl.text = m.harga.toString();
      _stokCtrl.text = m.stok.toString();
      _gambarCtrl.text = m.gambarUrl;
      _selectedKategori = m.kategori;
      _isAvailable = m.isAvailable;
      _standCtrl.text = m.namaStand;
    } else {
      // Prefill dengan nama stand akun pedagang yang sedang login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = context.read<AppAuthProvider>();
        if (_standCtrl.text.isEmpty) {
          _standCtrl.text = auth.currentUser?.namaStand.isNotEmpty == true
              ? auth.currentUser!.namaStand
              : (auth.currentUser?.nama ?? 'Kantin');
        }
      });
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _stokCtrl.dispose();
    _gambarCtrl.dispose();
    _standCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final auth = context.read<AppAuthProvider>();
      final currentUser = auth.currentUser;
      final currentUid = currentUser?.uid ?? '';
      final standName = _standCtrl.text.trim();

      // Sinkronkan nama stand ke profil pedagang jika belum tersimpan
      if (currentUser != null && (currentUser.namaStand.isEmpty || currentUser.namaStand != standName)) {
        auth.updateNamaStand(standName);
      }

      final menu = MenuModel(
        menuId: widget.menu?.menuId ?? '',
        namaMenu: _namaCtrl.text.trim(),
        kategori: _selectedKategori,
        harga: int.parse(_hargaCtrl.text.trim()),
        stok: int.parse(_stokCtrl.text.trim()),
        gambarUrl: _gambarCtrl.text.trim(),
        isAvailable: _isAvailable,
        penjualId: currentUid, // Selalu terikat ke UID akun pedagang yang sedang aktif
        namaStand: standName,
      );

      if (_isEditing) {
        await MenuService().updateMenu(menu);
      } else {
        await MenuService().addMenu(menu);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Menu berhasil diperbarui!' : 'Menu berhasil ditambahkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Menu' : 'Tambah Menu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview gambar jika ada URL
              if (_gambarCtrl.text.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _gambarCtrl.text,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.broken_image, size: 48,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _standCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Stand / Kantin',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  hintText: 'Contoh: Kantin Bu Siti',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama stand wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Menu',
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama menu wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              // Kategori dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.kategoriMenu
                    .skip(1) // skip 'Semua'
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedKategori = val!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        prefixIcon: Icon(Icons.money),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Harga wajib diisi';
                        if (int.tryParse(v) == null) return 'Harga harus angka';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stokCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Stok wajib diisi';
                        if (int.tryParse(v) == null) return 'Stok harus angka';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _gambarCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar (opsional)',
                  prefixIcon: Icon(Icons.image_outlined),
                  hintText: 'https://...',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              // Toggle ketersediaan
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Status Tersedia',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(_isAvailable ? 'Menu aktif & dapat dipesan' : 'Menu dinonaktifkan sementara'),
                  value: _isAvailable,
                  activeThumbColor: AppColors.success,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(_isSaving
                      ? 'Menyimpan...'
                      : (_isEditing ? 'Simpan Perubahan' : 'Tambah Menu')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
