# **Product Requirements Document (PRD)**

**Nama Produk:** Smart Canteen (Aplikasi Pemesanan Kantin Sekolah Tanpa Antre)

**Target Level:** Proyek Akhir / UKK SMK Kelas XII Rekayasa Perangkat Lunak (RPL)

**Tech Stack:** Flutter (Frontend Mobile), Firebase Authentication, Cloud Firestore (Database), Firebase Cloud Messaging / FCM (Push Notification)

## **1\. Latar Belakang & Tujuan Masalah**

### **1.1 Masalah**

Waktu istirahat sekolah umumnya hanya berlangsung 15–30 menit. Penumpukan antrean fisik di kantin sering membuat siswa kehabisan waktu istirahat hanya untuk menunggu makanan dibuat, atau bahkan kehabisan stok menu favorit. Di sisi lain, penjaga kantin kesulitan mencatat pesanan secara manual saat kondisi ramai.

### **1.2 Solusi**

**Smart Canteen** memungkinkan siswa melihat ketersediaan menu secara *real-time*, memesan makanan dari kelas sebelum bel istirahat berbunyi, dan menerima notifikasi otomatis (FCM) di ponsel mereka begitu pesanan selesai disiapkan dan siap diambil.

## **2\. Target Pengguna (*User Roles*)**

Aplikasi ini menerapkan sistem otorisasi berbasis peran (*Role-Based Access Control*) yang dibagi menjadi dua aktor utama:

1. **Siswa (Pembeli):**  
   * Melihat daftar menu yang tersedia dan stoknya secara *real-time*.  
   * Menambahkan menu ke keranjang belanja dan membuat pesanan (*checkout*).  
   * Memantau status pesanan (Menunggu, Dimasak, Siap Diambil, Selesai).  
   * Menerima notifikasi *push* saat pesanan siap diambil.  
2. **Penjual (Pengelola Kantin):**  
   * Mengelola daftar menu (Tambah, Ubah harga/stok, Hapus menu, Toggle status Habis/Tersedia).  
   * Menerima notifikasi *push* saat ada pesanan baru masuk dari siswa.  
   * Mengubah status pesanan siswa secara bertahap hingga selesai diambil.

## **3\. Kebutuhan Fungsional (*Functional Requirements*)**

### **3.1 Modul Autentikasi & Manajemen Role**

* **FR-01:** Pengguna dapat melakukan registrasi menggunakan Email sekolah/pribadi, Password, Nama Lengkap, Kelas (khusus siswa), dan memilih Role (siswa atau penjual).  
* **FR-02:** Sistem menyimpan fcmToken perangkat ke dokumen pengguna di Firestore setiap kali berhasil login agar notifikasi terkirim ke perangkat yang tepat.  
* **FR-03:** Sistem mengarahkan pengguna ke halaman *Dashboard* yang sesuai dengan role-nya secara otomatis setelah login.

### **3.2 Modul Katalog Menu (Siswa & Penjual)**

* **FR-04 (Penjual):** Penjual dapat menambah/mengedit menu meliputi: Nama Menu, Kategori (Makanan Berat, Snack, Minuman), Harga, Stok harian, dan URL Gambar.  
* **FR-05 (Siswa):** Siswa dapat mencari menu berdasarkan nama atau memfilter berdasarkan kategori.  
* **FR-06 (Real-time):** Jika stok menu bernilai 0 atau dinonaktifkan penjual, tombol "Tambah" otomatis terkunci (*disabled*) di layar siswa secara instan menggunakan StreamBuilder.

### **3.3 Modul Pemesanan & Keranjang (Siswa)**

* **FR-07:** Siswa dapat menambahkan beberapa item menu ke keranjang, mengatur jumlah (*quantity*), dan menambahkan catatan singkat (misal: *"Tidak pedas"*, *"Es sedikit"*).  
* **FR-08:** Sistem menghitung total harga secara otomatis. Metode pembayaran diatur ke **Bayar di Tempat / Tunai saat Pengambilan (COD Kantin)** untuk menyederhanakan alur transaksi tanpa *payment gateway* berbayar.  
* **FR-09:** Saat siswa menekan **"Pesan Sekarang"**, sistem membuat nomor antrean unik (misal: \#A-012), mengurangi stok menu terkait di Firestore, dan menyimpan data pesanan.

### **3.4 Modul Manajemen Pesanan & Notifikasi FCM**

* **FR-10:** Pesanan baru langsung muncul di layar *Dashboard* Penjual tanpa perlu *refresh* manual.  
* **FR-11 (Trigger FCM 1):** Ketika pesanan berhasil dibuat oleh Siswa, aplikasi memicu notifikasi FCM ke perangkat Penjual: *"Pesanan Baru \#A-012 dari Budi (XII RPL 1)"*.  
* **FR-12:** Penjual dapat mengubah status pesanan: Menunggu ![][image1] Dimasak ![][image1] Siap Diambil ![][image1] Selesai.  
* **FR-13 (Trigger FCM 2):** Ketika Penjual mengubah status menjadi Siap Diambil, aplikasi memicu notifikasi FCM ke perangkat Siswa pemesan: *"Pesanan \#A-012 Sudah Siap\! Silakan ambil di kantin."*

## **4\. Rancangan Struktur Database (Cloud Firestore)**

Untuk efisiensi pembacaan data (*read*) di paket gratis Firebase (*Spark Plan*), struktur koleksi dirancang datar (*flat*) dengan 3 koleksi utama:

### **4.1 Koleksi users**

Document ID: {uid} (dari Firebase Auth)

{  
  "uid": "user\_123abc",  
  "nama": "Ahmad Fauzi",  
  "email": "ahmad@smk.sch.id",  
  "role": "siswa", // "siswa" \| "penjual"  
  "kelas": "XII RPL 2", // kosong jika penjual  
  "fcmToken": "d8f7s8df7s8d7f8s7df..."  
}

### **4.2 Koleksi menus**

Document ID: Auto-generated ID

{  
  "menuId": "menu\_001",  
  "namaMenu": "Nasi Ayam Geprek",  
  "kategori": "Makanan Berat",  
  "harga": 12000,  
  "stok": 15,  
  "gambarUrl": "https\://...",  
  "isAvailable": true  
}

### **4.3 Koleksi orders**

Document ID: Auto-generated ID

{  
  "orderId": "ord\_987xyz",  
  "nomorAntrean": "A-014",  
  "siswaId": "user\_123abc",  
  "namaSiswa": "Ahmad Fauzi",  
  "kelasSiswa": "XII RPL 2",  
  "siswaFcmToken": "d8f7s8df7s8d7f8s7df...",  
  "items": \[  
    {  
      "menuId": "menu\_001",  
      "namaMenu": "Nasi Ayam Geprek",  
      "harga": 12000,  
      "qty": 1,  
      "catatan": "Sambal dipisah"  
    }  
  \],  
  "totalHarga": 12000,  
  "status": "Siap Diambil", // "Menunggu" \| "Dimasak" \| "Siap Diambil" \| "Selesai"  
  "createdAt": "Timestamp"  
}

## **5\. Kebutuhan Non-Fungsional & Batasan Teknis**

1. **Performa Real-Time:** Perubahan stok dan status pesanan harus tampil di perangkat lawan maksimal dalam waktu ![][image2] detik pada koneksi internet standar.  
2. **Penanganan FCM Tanpa Cloud Functions:** Karena proyek ini menggunakan Firebase paket gratis (*Spark Plan*), pengiriman pesan FCM dilakukan menggunakan **FCM HTTP v1 API** langsung dari kode Dart (menggunakan paket googleapis\_auth dan http dengan file kredensial *Service Account* yang disimpan secara aman) saat tombol aksi ditekan.  
3. **Validasi Input:** Aplikasi tidak boleh mengizinkan pemesanan jika stok di database sudah bernilai 0 (pencegahan *race condition* sederhana menggunakan *Firestore Transaction* saat *checkout*).

## **6\. Kriteria Keberhasilan (*Acceptance Criteria* Ujian/Demo)**

* \[ \] Login dengan 2 akun berbeda (Siswa & Penjual) pada 2 perangkat/emulator mengarah ke tampilan yang berbeda.  
* \[ \] Siswa melakukan pemesanan ![][image1] stok menu otomatis berkurang di database.  
* \[ \] Notifikasi FCM masuk ke HP Penjual saat pesanan dibuat (baik saat aplikasi dibuka maupun di *background*).  
* \[ \] Penjual mengubah status ke Siap Diambil ![][image1] notifikasi FCM masuk ke HP Siswa dan status di halaman *Pesanan Saya* berubah seketika.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAYAAACpF6WWAAAAlElEQVR4XmNgGAWjYGCBlJSUrLy8fLeCggIHuhzZQElJiR9o6GYg1kSXowgoKyuLAQ3djy5OMVBUVDSTkZFRQReHA1FRUR6gzZKkYjk5uUdAOgloOCe6mWQBcXFxbqCBfVQzEAhYgAZOBdKM6BJkA6C3XYGGrkYXpwSwANPoQiD2QJcgGxgbG7MCw1GIgZpeHwUEAQCknBX8GO53nAAAAABJRU5ErkJggg==>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAWCAYAAAChWZ5EAAABlElEQVR4Xu2UMUvDQBTHU1RQFBWlVEnStCUiLg4GFERwE0rRQRdH0cFPoC4OfgI3cVZ3cSs6dXNxtiAO4iA41C8gor8nV7g8LY2VbvnBn/Du/XPvXe5yjpOS0kUKhUK/53lTQRDMEWZ0vqtQdA818vn8M8839EhDy9rXLTIUvAjDcNjEPcQfRhsxZ1KKxeIsL1dR3ff9FZ23wVNGn6z+wBpblzH0zviS7W+HdF9Bt2hRYm3Q4JuR1dLoWnOMoqumAVHZ9v9KLpcbxLiDXtC5zrcjm80O2TH7v2uKN6RBO/cD13XHMb2iYzSp853APDVpgC9xStir8xk6vCH5wHMziqI+bfgPnJ955r7mlxzTuW8oOkp3T2bP2u7xX6BoyNx1ngM6F4MupzFemj3f1vlOYE6mCu5Z/X5zjMUu0Ixr+2LInqMTdChnQeeTQqEJ2Va05ZhbUA4mzVyhKO5ugZwFORPyCeUecBJep6VSaUQOXAvV9B+SBLkL5B64QxWJtcFG/fMxsaAz7U+MnBOZAB3pXEpKp3wBWjNide6T4ZQAAAAASUVORK5CYII=>