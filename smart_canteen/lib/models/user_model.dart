import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final String kelas;
  final String namaStand;
  final String fcmToken;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.kelas = '',
    this.namaStand = '',
    this.fcmToken = '',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      kelas: data['kelas'] ?? '',
      namaStand: data['namaStand'] ?? '',
      fcmToken: data['fcmToken'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'role': role,
      'kelas': kelas,
      'namaStand': namaStand,
      'fcmToken': fcmToken,
    };
  }

  bool get isSiswa => role == 'siswa';
  bool get isPenjual => role == 'penjual';

  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? role,
    String? kelas,
    String? namaStand,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      kelas: kelas ?? this.kelas,
      namaStand: namaStand ?? this.namaStand,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
