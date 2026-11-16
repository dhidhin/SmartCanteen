import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String menuId;
  final String namaMenu;
  final int harga;
  final int qty;
  final String catatan;

  OrderItemModel({
    required this.menuId,
    required this.namaMenu,
    required this.harga,
    required this.qty,
    this.catatan = '',
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuId: map['menuId'] ?? '',
      namaMenu: map['namaMenu'] ?? '',
      harga: (map['harga'] ?? 0).toInt(),
      qty: (map['qty'] ?? 1).toInt(),
      catatan: map['catatan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'namaMenu': namaMenu,
      'harga': harga,
      'qty': qty,
      'catatan': catatan,
    };
  }
}

class OrderModel {
  final String orderId;
  final String nomorAntrean;
  final String siswaId;
  final String namaSiswa;
  final String kelasSiswa;
  final String siswaFcmToken;
  final String penjualId;
  final String namaStand;
  final List<OrderItemModel> items;
  final int totalHarga;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.nomorAntrean,
    required this.siswaId,
    required this.namaSiswa,
    required this.kelasSiswa,
    required this.siswaFcmToken,
    this.penjualId = '',
    this.namaStand = '',
    required this.items,
    required this.totalHarga,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    DateTime createdAt;
    try {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } catch (_) {
      createdAt = DateTime.now();
    }

    return OrderModel(
      orderId: doc.id,
      nomorAntrean: data['nomorAntrean'] ?? '',
      siswaId: data['siswaId'] ?? '',
      namaSiswa: data['namaSiswa'] ?? '',
      kelasSiswa: data['kelasSiswa'] ?? '',
      siswaFcmToken: data['siswaFcmToken'] ?? '',
      penjualId: data['penjualId'] ?? '',
      namaStand: data['namaStand'] ?? '',
      items: itemsList,
      totalHarga: (data['totalHarga'] ?? 0).toInt(),
      status: data['status'] ?? 'Menunggu',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomorAntrean': nomorAntrean,
      'siswaId': siswaId,
      'namaSiswa': namaSiswa,
      'kelasSiswa': kelasSiswa,
      'siswaFcmToken': siswaFcmToken,
      'penjualId': penjualId,
      'namaStand': namaStand,
      'items': items.map((i) => i.toMap()).toList(),
      'totalHarga': totalHarga,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get nextStatus {
    switch (status) {
      case 'Menunggu':
        return 'Dimasak';
      case 'Dimasak':
        return 'Siap Diambil';
      case 'Siap Diambil':
        return 'Selesai';
      default:
        return 'Selesai';
    }
  }

  bool get canAdvance => status != 'Selesai';
}
