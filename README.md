# 🍱 Smart Canteen (Aplikasi Pemesanan Kantin Sekolah Tanpa Antre)

Proyek Akhir / UKK SMK Kelas XII Rekayasa Perangkat Lunak (RPL).

Aplikasi mobile Android berbasis **Flutter** dan **Firebase** (Authentication, Cloud Firestore, Cloud Messaging) yang memungkinkan siswa memesan makanan dari kelas sebelum bel istirahat, serta menerima notifikasi saat pesanan siap diambil di kantin sekolah.

---

## 🚀 Fitur Utama

### 👨‍🎓 Role: Siswa (Pembeli)
- **Registrasi & Login**: Form pendaftaran khusus siswa mencakup Nama Lengkap, Kelas (misal: `XII RPL 1`), Email, dan Password.
- **Katalog Menu Real-time**:
  - Filter kategori (*Makanan Berat*, *Snack*, *Minuman*).
  - Kolom pencarian menu instan.
  - Indikator stok harian (Otomatis terkunci/disabled jika stok habis atau dinonaktifkan oleh penjual via `StreamBuilder`).
- **Keranjang & Catatan Khusus**:
  - Pengaturan jumlah pesanan (*increment/decrement*).
  - Tambah catatan per menu (contoh: *"Sambal dipisah"*, *"Es sedikit"*).
  - Metode pembayaran: **Bayar di Tempat / Tunai saat Pengambilan (COD Kantin)**.
- **Checkout Aman (Firestore Transaction)**:
  - Generate nomor antrean otomatis unik (misal: `#A-001`).
  - Pengurangan stok menggunakan transaksi database Firestore untuk mencegah *race condition*.
- **Notifikasi Push (FCM)**:
  - Menerima notifikasi otomatis ketika penjual mengubah status menjadi **Siap Diambil**.
- **Pantau Status Pesanan**:
  - Layar *Pesanan Saya* dengan status dinamis (*Menunggu* ⏳, *Dimasak* 🔥, *Siap Diambil* ✅, *Selesai* 🏁).

---

### 👨‍🍳 Role: Penjual (Pengelola Kantin / Multi-Stand)
- **Nama Stand / Kantin**: Saat registrasi akun penjual, penjual dapat mengisi nama standnya (contoh: *Kantin Bu Siti*, *Stand Es Segar*).
- **Dashboard Pesanan Khusus Stand**:
  - Penjual hanya menerima dan mengelola pesanan yang ditujukan ke stand miliknya (`where('penjualId', isEqualTo: currentUserId)`).
  - Pesanan baru dari siswa langsung muncul seketika tanpa refresh manual.
  - Filter pesanan berdasarkan status: *Semua*, *Menunggu*, *Dimasak*, *Siap Diambil*, *Selesai*.
  - Notifikasi otomatis masuk ke HP penjual bersangkutan saat ada pesanan baru.
- **Kelola Menu per Stand**:
  - Penjual menambah dan mengedit menu khusus untuk stand miliknya.
  - Nama stand otomatis disematkan pada setiap menu yang dibuat.

---

### 🛍️ Fitur Multi-Pedagang: Split-Order (Opsi B)
- **Pesan Campur Sekaligus**: Siswa dapat memasukkan menu dari beberapa stand pedagang berbeda ke dalam satu keranjang (contoh: Nasi Ayam dari *Stand Bu Siti* + Es Teh dari *Stand Es Segar*).
- **Otomatis Dipecah (*Auto-Split*)**: Saat siswa menekan **Pesan Sekarang**, sistem secara otomatis:
  1. Memecah pesanan menjadi dokumen pesanan terpisah untuk masing-masing stand.
  2. Memberikan nomor antrean untuk masing-masing stand (misal: `#A-001 (Kantin Bu Siti)` dan `#A-002 (Stand Es Segar)`).
  3. Mengirimkan notifikasi FCM secara spesifik hanya ke pedagang stand terkait.
- **Tracking Transparan**: Di halaman *Pesanan Saya*, siswa dapat melihat status setiap pesanan per stand secara mandiri. Notifikasi FCM akan berbunyi saat masing-masing stand telah menyiapkan makanannya.

---

## 🏗️ Struktur Arsitektur Kode

```
lib/
├── main.dart                        # Inisialisasi Firebase, FCM & Local Notification
├── models/
│   ├── user_model.dart              # Model User (uid, nama, email, role, kelas, fcmToken)
│   ├── menu_model.dart              # Model Menu (menuId, namaMenu, kategori, harga, stok, gambarUrl, isAvailable)
│   ├── cart_item_model.dart         # Model Keranjang Belanja
│   └── order_model.dart             # Model Pesanan (nomorAntrean, status, items, siswaId, totalHarga, dll)
├── providers/
│   ├── auth_provider.dart           # AppAuthProvider (State management otentikasi)
│   └── cart_provider.dart           # CartProvider (State management keranjang belanja)
├── services/
│   ├── auth_service.dart            # Firebase Auth & Firestore User Management
│   ├── menu_service.dart            # Cloud Firestore Menu CRUD & Streams
│   ├── order_service.dart           # Cloud Firestore Order Transactions & Status Updates
│   └── fcm_service.dart             # Pengiriman FCM v1 API langsung via Service Account (Bebas Cloud Functions)
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart       # Splash & redirect otomatis berdasarkan Role
│   │   ├── login_screen.dart        # Login Form
│   │   └── register_screen.dart     # Registrasi Siswa/Penjual
│   ├── siswa/
│   │   ├── siswa_home_screen.dart   # Katalog menu & filter
│   │   ├── cart_screen.dart         # Keranjang & checkout COD
│   │   ├── order_success_screen.dart# Konfirmasi sukses & nomor antrean
│   │   └── pesanan_saya_screen.dart # Riwayat pesanan siswa
│   └── penjual/
│       ├── penjual_home_screen.dart # Dashboard pesanan kantin
│       ├── kelola_menu_screen.dart  # Katalog kelola menu penjual
│       └── tambah_edit_menu_screen.dart # Form tambah/edit menu
├── widgets/
│   ├── menu_card_siswa.dart         # Kartu menu dengan tombol tambah/kurang instan
│   ├── badge_cart_icon.dart         # Icon keranjang dengan badge jumlah item
│   └── order_status_badge.dart      # Badge warna status pesanan
└── utils/
    ├── app_colors.dart              # Skema warna aplikasi
    ├── app_theme.dart               # Konfigurasi Theme Material 3 & Font Poppins
    └── constants.dart               # Konstanta koleksi Firestore & Role
```

---

## ⚙️ Panduan Setup & Menjalankan

1. **Unduh dependencies**:
   ```bash
   flutter pub get
   ```

2. **Hubungkan Firebase**:
   - Daftarkan aplikasi di [Firebase Console](https://console.firebase.google.com).
   - Letakkan file konfigurasi `google-services.json` ke folder `android/app/`.
   - Unduh **Private Key Service Account** dari Firebase Console (*Project settings* > *Service accounts*) dan simpan ke `assets/service_account.json`.

3. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

Lihat panduan lengkap di file artifact [SmartCanteen_Setup_Guide.md](file:///C:/Users/USER/.gemini/antigravity/brain/ed61d0f9-519c-4bc7-9213-4d3653600081/SmartCanteen_Setup_Guide.md).
