import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  final String menuId;
  final String namaMenu;
  final String kategori;
  final int harga;
  final int stok;
  final String gambarUrl;
  final bool isAvailable;
  final String penjualId;
  final String namaStand;

  MenuModel({
    required this.menuId,
    required this.namaMenu,
    required this.kategori,
    required this.harga,
    required this.stok,
    this.gambarUrl = '',
    this.isAvailable = true,
    this.penjualId = '',
    this.namaStand = '',
  });

  factory MenuModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuModel(
      menuId: doc.id,
      namaMenu: data['namaMenu'] ?? '',
      kategori: data['kategori'] ?? '',
      harga: (data['harga'] ?? 0).toInt(),
      stok: (data['stok'] ?? 0).toInt(),
      gambarUrl: data['gambarUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      penjualId: data['penjualId'] ?? '',
      namaStand: data['namaStand'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaMenu': namaMenu,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'gambarUrl': gambarUrl,
      'isAvailable': isAvailable,
      'penjualId': penjualId,
      'namaStand': namaStand,
    };
  }

  bool get isOrderable => isAvailable && stok > 0;

  MenuModel copyWith({
    String? menuId,
    String? namaMenu,
    String? kategori,
    int? harga,
    int? stok,
    String? gambarUrl,
    bool? isAvailable,
    String? penjualId,
    String? namaStand,
  }) {
    return MenuModel(
      menuId: menuId ?? this.menuId,
      namaMenu: namaMenu ?? this.namaMenu,
      kategori: kategori ?? this.kategori,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      penjualId: penjualId ?? this.penjualId,
      namaStand: namaStand ?? this.namaStand,
    );
  }
}
