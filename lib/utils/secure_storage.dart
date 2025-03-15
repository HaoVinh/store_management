import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/auth_screen/model/auth_response.dart';

class SecureStorageFrave {

  //Auto login when exit app and app is opened
  final secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    wOptions: WindowsOptions(),
  );

  persisAuthShare(AuthResponse auth) async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('auth', jsonEncode(auth.toJson()));
    });
  }

  readAuthShare() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var auth = prefs.getString('auth');
    if (auth != null) {
      return AuthResponse.fromJson(jsonDecode(auth));
    }
  }

  //delete
  deleteAuthShare() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('auth');
  }



  Future<void> persistAuth(AuthResponse auth) async {
    await secureStorage.write(key: 'auth', value: jsonEncode(auth.toJson()));
  }

  Future<AuthResponse?> readAuth() async {
    final data = await secureStorage.read(key: 'auth');
    if (data != null) {
      return AuthResponse.fromJson(jsonDecode(data));
    }
    return null;
  }
  // Đọc dữ liệu auth từ SecureStorage

  Future<void> deleteSecureStorage() async {
    await secureStorage.delete(key: 'token');
    await secureStorage.deleteAll();
  }
  // Xóa key token khi đăng xuất
}

final secureStorage = SecureStorageFrave();
