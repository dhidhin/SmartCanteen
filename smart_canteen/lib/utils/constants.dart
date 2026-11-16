class AppConstants {
  static const String appName = 'Smart Canteen';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String menusCollection = 'menus';
  static const String ordersCollection = 'orders';

  // User Roles
  static const String roleSiswa = 'siswa';
  static const String rolePenjual = 'penjual';

  // Order Status
  static const String statusMenunggu = 'Menunggu';
  static const String statusDimasak = 'Dimasak';
  static const String statusSiapDiambil = 'Siap Diambil';
  static const String statusSelesai = 'Selesai';

  // Kategori Menu
  static const List<String> kategoriMenu = [
    'Semua',
    'Makanan Berat',
    'Snack',
    'Minuman',
  ];

  // FCM
  static const String fcmApiUrl =
      'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send';
}
