import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FcmService {
  static const String _fcmScope =
      'https://www.googleapis.com/auth/firebase.messaging';

  static Future<String?> _getAccessToken() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/service_account.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      final credentials = ServiceAccountCredentials.fromJson(jsonMap);
      final client = await clientViaServiceAccount(
        credentials,
        [_fcmScope],
      );
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('Error getting FCM access token: $e');
      return null;
    }
  }

  static Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('FCM: Could not get access token');
        return;
      }

      // Ambil project ID dari service account
      final jsonString =
          await rootBundle.loadString('assets/service_account.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final projectId = jsonMap['project_id'] as String;

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
              'sound': 'default',
              'priority': 'high',
            },
          },
          if (data != null) 'data': data,
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM notification sent successfully');
      } else {
        debugPrint('FCM error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM send error: $e');
    }
  }

  /// Kirim notifikasi ke penjual saat ada pesanan baru
  static Future<void> notifyPenjual({
    required String penjualFcmToken,
    required String nomorAntrean,
    required String namaSiswa,
    required String kelasSiswa,
  }) async {
    await sendNotification(
      fcmToken: penjualFcmToken,
      title: '🍽️ Pesanan Baru!',
      body: 'Pesanan #$nomorAntrean dari $namaSiswa ($kelasSiswa)',
      data: {'type': 'new_order', 'nomorAntrean': nomorAntrean},
    );
  }

  /// Kirim notifikasi ke siswa saat pesanan siap diambil
  static Future<void> notifySiswa({
    required String siswaFcmToken,
    required String nomorAntrean,
    String namaStand = '',
  }) async {
    final standText = namaStand.isNotEmpty ? ' di $namaStand' : '';
    await sendNotification(
      fcmToken: siswaFcmToken,
      title: '✅ Pesananmu Siap!',
      body: 'Pesanan #$nomorAntrean$standText sudah siap. Silakan ambil!',
      data: {'type': 'order_ready', 'nomorAntrean': nomorAntrean},
    );
  }
}
