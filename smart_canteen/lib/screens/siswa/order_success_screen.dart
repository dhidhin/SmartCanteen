import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'pesanan_saya_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final List<String> antreanList;

  OrderSuccessScreen({
    super.key,
    List<String>? antreanList,
    String? nomorAntrean,
  }) : antreanList = antreanList ?? (nomorAntrean != null ? [nomorAntrean] : ['-']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pesanan Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  antreanList.length > 1
                      ? 'Pesananmu otomatis dipecah ke ${antreanList.length} stand kantin:'
                      : 'Pesananmu sedang diproses oleh penjual',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                // Daftar nomor antrean
                ...antreanList.map((antrean) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.confirmation_number_outlined,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          '#$antrean',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Text(
                  '💡 Notifikasi akan berbunyi saat masing-masing pesanan siap diambil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Lihat Status Pesanan'),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PesananSayaScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Kembali ke Menu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
