import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/repositories/abstract_repository.dart';

import '../../../utils/secure_storage.dart';
import '../model/auth_response.dart';

class AuthRepository extends AbstractRepository {
  final String _finalUrl = '/account';

  Future<AuthResponse?> login(String username, String password) async {
    try {
      final response = await post(url: '$_finalUrl/login', data: {
        'userName': username,
        'passWord': password,

      });
      final authResponse = AuthResponse.fromJson(response.data);
      //Hiện tại set cứng ,sau này return authResponse;
      authResponse.id = 16413;
      authResponse.branchName = "555 KINGMART 108";
// Sau khi login thành công thì sẽ trả về id chi nhánh và branchName theo user login.
      return authResponse;

    } on DioError catch (e) {
      if (e.response?.statusCode == 400) {
        return AuthResponse(message: e.response?.data['msg']);
      } else {
        return AuthResponse(message: e.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse?> renewLoginController() async {
    try {
      final token = await secureStorage.readAuth();

      final response = await post(url: '$_finalUrl/renew-token', data: {
        'token': token!.accessToken,
      });

      return AuthResponse.fromJson(response.data);
    } on DioError catch (e) {
      //400
      if (e.response?.statusCode == 400) {
        return AuthResponse(message: 'Phiên đăng nhập đã hết hạn');
      } else {
        return AuthResponse(message: 'Lỗi không xác định');
      }
    } catch (e) {
      rethrow;
    }
  }
}
