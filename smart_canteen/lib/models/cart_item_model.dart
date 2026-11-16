class CartItemModel {
  final String menuId;
  final String namaMenu;
  final int harga;
  final String penjualId;
  final String namaStand;
  int qty;
  String catatan;

  CartItemModel({
    required this.menuId,
    required this.namaMenu,
    required this.harga,
    this.penjualId = '',
    this.namaStand = '',
    this.qty = 1,
    this.catatan = '',
  });

  int get subtotal => harga * qty;

  CartItemModel copyWith({
    String? menuId,
    String? namaMenu,
    int? harga,
    String? penjualId,
    String? namaStand,
    int? qty,
    String? catatan,
  }) {
    return CartItemModel(
      menuId: menuId ?? this.menuId,
      namaMenu: namaMenu ?? this.namaMenu,
      harga: harga ?? this.harga,
      penjualId: penjualId ?? this.penjualId,
      namaStand: namaStand ?? this.namaStand,
      qty: qty ?? this.qty,
      catatan: catatan ?? this.catatan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'namaMenu': namaMenu,
      'harga': harga,
      'penjualId': penjualId,
      'namaStand': namaStand,
      'qty': qty,
      'catatan': catatan,
    };
  }
}
