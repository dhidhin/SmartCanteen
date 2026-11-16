import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream semua menu (real-time)
  Stream<List<MenuModel>> getMenuStream() {
    return _firestore
        .collection('menus')
        .orderBy('namaMenu')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MenuModel.fromFirestore(doc)).toList());
  }

  /// Stream menu khusus akun penjual tertentu (hanya menu milik stand ini)
  Stream<List<MenuModel>> getPenjualMenuStream(String penjualId) {
    return _firestore
        .collection('menus')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => MenuModel.fromFirestore(doc))
          .where((m) => m.penjualId == penjualId)
          .toList();
      list.sort((a, b) => a.namaMenu.compareTo(b.namaMenu));
      return list;
    });
  }

  /// Ambil menu lama yang belum terikat ke pedagang mana pun
  Stream<List<MenuModel>> getUnassignedMenuStream() {
    return _firestore
        .collection('menus')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MenuModel.fromFirestore(doc))
            .where((m) => m.penjualId.isEmpty)
            .toList());
  }

  /// Hubungkan menu yang belum terikat ke akun stand saat ini
  Future<void> assignMenuToPenjual({
    required String menuId,
    required String penjualId,
    required String namaStand,
  }) async {
    await _firestore.collection('menus').doc(menuId).update({
      'penjualId': penjualId,
      'namaStand': namaStand,
    });
  }

  /// Tambah menu baru
  Future<void> addMenu(MenuModel menu) async {
    await _firestore.collection('menus').add(menu.toMap());
  }

  /// Update menu
  Future<void> updateMenu(MenuModel menu) async {
    await _firestore
        .collection('menus')
        .doc(menu.menuId)
        .update(menu.toMap());
  }

  /// Hapus menu
  Future<void> deleteMenu(String menuId) async {
    await _firestore.collection('menus').doc(menuId).delete();
  }

  /// Toggle ketersediaan
  Future<void> toggleAvailability(String menuId, bool isAvailable) async {
    await _firestore.collection('menus').doc(menuId).update({
      'isAvailable': isAvailable,
    });
  }

  /// Update stok saja
  Future<void> updateStok(String menuId, int stok) async {
    await _firestore.collection('menus').doc(menuId).update({'stok': stok});
  }
}
