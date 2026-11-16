import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.qty);
  int get totalHarga => _items.fold(0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  void addItem({
    required String menuId,
    required String namaMenu,
    required int harga,
    String penjualId = '',
    String namaStand = '',
  }) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    if (idx >= 0) {
      _items[idx].qty++;
    } else {
      _items.add(CartItemModel(
        menuId: menuId,
        namaMenu: namaMenu,
        harga: harga,
        penjualId: penjualId,
        namaStand: namaStand,
      ));
    }
    notifyListeners();
  }

  void removeItem(String menuId) {
    _items.removeWhere((i) => i.menuId == menuId);
    notifyListeners();
  }

  void decreaseQty(String menuId) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    if (idx >= 0) {
      if (_items[idx].qty <= 1) {
        _items.removeAt(idx);
      } else {
        _items[idx].qty--;
      }
    }
    notifyListeners();
  }

  void updateCatatan(String menuId, String catatan) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    if (idx >= 0) {
      _items[idx].catatan = catatan;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int getQty(String menuId) {
    final item = _items.where((i) => i.menuId == menuId).firstOrNull;
    return item?.qty ?? 0;
  }
}
