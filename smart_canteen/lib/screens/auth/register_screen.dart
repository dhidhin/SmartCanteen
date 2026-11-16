import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../siswa/siswa_home_screen.dart';
import '../penjual/penjual_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _namaStandCtrl = TextEditingController();
  String _selectedRole = AppConstants.roleSiswa;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _kelasCtrl.dispose();
    _namaStandCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AppAuthProvider>();
    final success = await authProvider.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      nama: _namaCtrl.text.trim(),
      role: _selectedRole,
      kelas: _selectedRole == AppConstants.roleSiswa
          ? _kelasCtrl.text.trim()
          : '',
      namaStand: _selectedRole == AppConstants.rolePenjual
          ? _namaStandCtrl.text.trim()
          : '',
    );

    if (!mounted) return;
    if (success) {
      final user = authProvider.currentUser!;
      Widget destination = user.isPenjual
          ? const PenjualHomeScreen()
          : const SiswaHomeScreen();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Selection
                        const Text(
                          'Daftar sebagai:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                label: 'Siswa',
                                icon: Icons.school,
                                isSelected:
                                    _selectedRole == AppConstants.roleSiswa,
                                onTap: () => setState(() =>
                                    _selectedRole = AppConstants.roleSiswa),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleCard(
                                label: 'Penjual',
                                icon: Icons.store,
                                isSelected:
                                    _selectedRole == AppConstants.rolePenjual,
                                onTap: () => setState(() =>
                                    _selectedRole = AppConstants.rolePenjual),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _namaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Email wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (v.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        if (_selectedRole == AppConstants.roleSiswa) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _kelasCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kelas (contoh: XII RPL 1)',
                              prefixIcon: Icon(Icons.class_outlined),
                            ),
                            validator: (v) {
                              if (_selectedRole == AppConstants.roleSiswa &&
                                  (v == null || v.isEmpty)) {
                                return 'Kelas wajib diisi untuk siswa';
                              }
                              return null;
                            },
                          ),
                        ] else if (_selectedRole == AppConstants.rolePenjual) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _namaStandCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nama Stand / Kantin (contoh: Kantin Bu Siti)',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: (v) {
                              if (_selectedRole == AppConstants.rolePenjual &&
                                  (v == null || v.isEmpty)) {
                                return 'Nama stand wajib diisi untuk penjual';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        Consumer<AppAuthProvider>(
                          builder: (_, auth, __) => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Daftar Sekarang'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
