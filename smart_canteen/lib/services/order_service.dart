import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/user_model.dart';
import 'fcm_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream pesanan khusus untuk stand penjual tertentu
  Stream<List<OrderModel>> getPenjualOrdersStream({
    required String penjualId,
    String namaStand = '',
  }) {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((snap) {
      final orders = snap.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .where((o) {
            // 1. Cocokkan berdasarkan UID penjual
            if (penjualId.isNotEmpty && o.penjualId == penjualId) {
              return true;
            }
            // 2. Jika penjualId pada order kosong (order lama), cocokkan berdasarkan nama stand
            if (o.penjualId.isEmpty &&
                namaStand.isNotEmpty &&
                o.namaStand.trim().toLowerCase() == namaStand.trim().toLowerCase()) {
              return true;
            }
            return false;
          })
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Stream pesanan lama yang belum memiliki stand/penjualId
  Stream<List<OrderModel>> getUnassignedOrdersStream() {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((snap) {
      final orders = snap.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .where((o) =>
              o.penjualId.isEmpty &&
              (o.namaStand.isEmpty ||
                  o.namaStand == 'Kantin' ||
                  o.namaStand == 'Kantin Sekolah'))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Klaim pesanan lama ke stand pedagang saat ini
  Future<void> assignOrderToPenjual({
    required String orderId,
    required String penjualId,
    required String namaStand,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'penjualId': penjualId,
      'namaStand': namaStand,
    });
  }

  /// Hapus pesanan lama (untuk pembersihan data testing)
  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  /// Stream semua pesanan (global)
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((snap) {
      final orders =
          snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Stream pesanan siswa tertentu (sort in-memory agar bebas dari kebutuhan Composite Index)
  Stream<List<OrderModel>> getSiswaOrdersStream(String siswaId) {
    return _firestore
        .collection('orders')
        .where('siswaId', isEqualTo: siswaId)
        .snapshots()
        .map((snap) {
      final orders =
          snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Buat pesanan baru dengan pemecahan otomatis per stand pedagang (Order Splitting - Opsi B)
  Future<List<String>> createOrder({
    required UserModel siswa,
    required List<CartItemModel> cartItems,
    String defaultPenjualFcmToken = '',
  }) async {
    try {
      // 1. Verifikasi dan lengkapi data penjualId & namaStand langsung dari dokumen Firestore
      final List<CartItemModel> enrichedItems = [];
      for (final item in cartItems) {
        String penjualId = item.penjualId;
        String namaStand = item.namaStand;

        try {
          final menuSnap =
              await _firestore.collection('menus').doc(item.menuId).get();
          if (menuSnap.exists) {
            final data = menuSnap.data() ?? {};
            final dbPenjualId = (data['penjualId'] as String?) ?? '';
            final dbNamaStand = (data['namaStand'] as String?) ?? '';

            if (dbPenjualId.isNotEmpty) {
              penjualId = dbPenjualId;
            }
            if (dbNamaStand.isNotEmpty) {
              namaStand = dbNamaStand;
            }
          }
        } catch (e) {
          debugPrint('Warning resolving menu from firestore: $e');
        }

        // Jika penjualId masih kosong tetapi namaStand ada, cari akun penjual dengan stand tersebut
        if (penjualId.isEmpty &&
            namaStand.isNotEmpty &&
            namaStand != 'Kantin Sekolah' &&
            namaStand != 'Kantin') {
          try {
            final userSnap = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'penjual')
                .where('namaStand', isEqualTo: namaStand)
                .limit(1)
                .get();
            if (userSnap.docs.isNotEmpty) {
              penjualId = userSnap.docs.first.id;
            }
          } catch (_) {}
        }

        enrichedItems.add(item.copyWith(
          penjualId: penjualId,
          namaStand: namaStand.isNotEmpty ? namaStand : 'Kantin Sekolah',
        ));
      }

      // 2. Kelompokkan item per stand/penjual agar setiap stand menerima pesanan terpisah
      final Map<String, List<CartItemModel>> groupedItems = {};
      for (final item in enrichedItems) {
        // Kunci grup unik: penjualId jika ada, atau stand_<namaStand>
        final key = item.penjualId.isNotEmpty
            ? item.penjualId
            : 'stand_${item.namaStand}';
        groupedItems.putIfAbsent(key, () => []).add(item);
      }

      final List<String> createdAntreanList = [];

      // 3. Proses pesanan per stand pedagang
      for (final entry in groupedItems.entries) {
        final itemsForStand = entry.value;
        final penjualId = itemsForStand.first.penjualId;
        final namaStand = itemsForStand.first.namaStand;

        final nomorAntrean = await _generateNomorAntrean();
        final totalHarga =
            itemsForStand.fold<int>(0, (total, item) => total + item.subtotal);

        final orderData = {
          'nomorAntrean': nomorAntrean,
          'siswaId': siswa.uid,
          'namaSiswa': siswa.nama,
          'kelasSiswa': siswa.kelas,
          'siswaFcmToken': siswa.fcmToken,
          'penjualId': penjualId,
          'namaStand': namaStand,
          'items': itemsForStand.map((i) => i.toMap()).toList(),
          'totalHarga': totalHarga,
          'status': 'Menunggu',
          'createdAt': FieldValue.serverTimestamp(),
        };

        try {
          // Coba atomic transaction: SEMUA READ DULU, LALU SEMUA WRITE
          await _firestore.runTransaction((transaction) async {
            final updates = <Map<String, dynamic>>[];

            // 1. ALL READS
            for (final item in itemsForStand) {
              final menuRef = _firestore.collection('menus').doc(item.menuId);
              final menuSnap = await transaction.get(menuRef);

              if (!menuSnap.exists) {
                throw Exception('Menu "${item.namaMenu}" tidak ditemukan di database.');
              }

              final data = menuSnap.data() ?? {};
              final currentStok = (data['stok'] as num?)?.toInt() ?? 0;
              final isAvailable = data['isAvailable'] as bool? ?? true;

              if (!isAvailable) {
                throw Exception('Menu "${item.namaMenu}" sedang tidak aktif.');
              }

              if (currentStok < item.qty) {
                throw Exception('Stok "${item.namaMenu}" tidak cukup (sisa: $currentStok).');
              }

              updates.add({
                'ref': menuRef,
                'newStok': currentStok - item.qty,
              });
            }

            // 2. ALL WRITES AFTER ALL READS
            for (final u in updates) {
              final ref = u['ref'] as DocumentReference<Map<String, dynamic>>;
              final newStok = u['newStok'] as int;
              transaction.update(ref, {'stok': newStok});
            }

            final orderRef = _firestore.collection('orders').doc();
            transaction.set(orderRef, orderData);
          });
        } catch (transactionError) {
          debugPrint('Transaction fallback for stand $namaStand: $transactionError');
          await _firestore.collection('orders').add(orderData);
          for (final item in itemsForStand) {
            try {
              final menuRef = _firestore.collection('menus').doc(item.menuId);
              final snap = await menuRef.get();
              if (snap.exists) {
                final currentStok = ((snap.data()?['stok'] as num?) ?? 0).toInt();
                if (currentStok >= item.qty) {
                  await menuRef.update({'stok': currentStok - item.qty});
                }
              }
            } catch (_) {}
          }
        }

        createdAntreanList.add('$nomorAntrean ($namaStand)');

        // Kirim notifikasi FCM ke penjual stand terkait
        _notifyPenjualStand(
          penjualId: penjualId,
          nomorAntrean: nomorAntrean,
          siswa: siswa,
          fallbackToken: defaultPenjualFcmToken,
        );
      }

      return createdAntreanList;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  void _notifyPenjualStand({
    required String penjualId,
    required String nomorAntrean,
    required UserModel siswa,
    required String fallbackToken,
  }) async {
    try {
      String token = '';
      if (penjualId.isNotEmpty) {
        final penjualDoc =
            await _firestore.collection('users').doc(penjualId).get();
        if (penjualDoc.exists) {
          token = (penjualDoc.data()?['fcmToken'] as String?) ?? '';
        }
      }
      if (token.isEmpty) {
        token = fallbackToken;
      }

      if (token.isNotEmpty) {
        await FcmService.notifyPenjual(
          penjualFcmToken: token,
          nomorAntrean: nomorAntrean,
          namaSiswa: siswa.nama,
          kelasSiswa: siswa.kelas,
        );
      }
    } catch (e) {
      debugPrint('Error notifying stand seller ($penjualId): $e');
    }
  }

  /// Update status pesanan oleh penjual
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
    required String siswaFcmToken,
    required String nomorAntrean,
    String namaStand = '',
    String penjualId = '',
  }) async {
    final updateData = <String, dynamic>{
      'status': newStatus,
    };
    if (penjualId.isNotEmpty) {
      updateData['penjualId'] = penjualId;
    }
    if (namaStand.isNotEmpty) {
      updateData['namaStand'] = namaStand;
    }

    await _firestore.collection('orders').doc(orderId).update(updateData);

    // Kirim notifikasi ke siswa saat Siap Diambil
    if (newStatus == 'Siap Diambil' && siswaFcmToken.isNotEmpty) {
      await FcmService.notifySiswa(
        siswaFcmToken: siswaFcmToken,
        nomorAntrean: nomorAntrean,
        namaStand: namaStand,
      );
    }
  }

  Future<String> _generateNomorAntrean() async {
    try {
      final snap = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      int nextNum = 1;
      if (snap.docs.isNotEmpty) {
        final lastAntrean = (snap.docs.first.data()['nomorAntrean'] ?? '') as String;
        // Format: A-001
        final parts = lastAntrean.split('-');
        if (parts.length == 2) {
          nextNum = (int.tryParse(parts[1]) ?? 0) + 1;
        }
      }

      return 'A-${nextNum.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Warning: Could not fetch last nomorAntrean, generating timestamp suffix: $e');
      final now = DateTime.now();
      final suffix = ((now.minute * 60 + now.second) % 900) + 100;
      return 'A-$suffix';
    }
  }
}
