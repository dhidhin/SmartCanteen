import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<void> loadCurrentUser(String uid) async {
    _currentUser = await _authService.getUserModel(uid);
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nama,
    required String role,
    String kelas = '',
    String namaStand = '',
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        nama: nama,
        role: role,
        kelas: kelas,
        namaStand: namaStand,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setError('Terjadi kesalahan. Coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setError('Terjadi kesalahan. Coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateNamaStand(String namaStand) async {
    if (_currentUser == null) return;
    await _authService.updateNamaStand(_currentUser!.uid, namaStand);
    _currentUser = _currentUser!.copyWith(namaStand: namaStand);
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter).';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}
