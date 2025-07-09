import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';
import 'dart:math' as Math;

class StorageService {
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_KEY = 'user_data';
  static const String ROLES_KEY = 'user_roles';
  static const String EMPLOYEE_KEY = 'employee_data';
  static const String TOKEN_EXPIRY_KEY = 'token_expiry';
  static const String TOKEN_TYPE_KEY = 'token_type';
  static const String USER_ID_KEY = 'user_id';

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLoginResponse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonData = prefs.getString('login_response');

      if (jsonData != null) {
        return json.decode(jsonData) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error loading login response: $e');
      return null;
    }
  }

  Future<bool> saveAuthData(String token, UserModel user,
      {String tokenType = 'Bearer', int expiresIn = 3600}) async {
    try {
      print('🔄 Starting saveAuthData...');
      print(
          '📥 Input - Token: ${token.substring(0, Math.min(15, token.length))}...');
      print('📥 Input - User: ${user.name}, ID: ${user.id}');
      print('📥 Input - Roles: ${user.roleNames}'); // Using roleNames getter
      print('📥 Input - TokenType: $tokenType, ExpiresIn: $expiresIn');

      final prefs = await _getPrefs();
      if (prefs == null) {
        print('❌ Failed to get SharedPreferences');
        return false;
      }

      // Save token information
      await prefs.setString(TOKEN_KEY, token);
      print('✅ Saved token');

      await prefs.setString(TOKEN_TYPE_KEY, tokenType);
      print('✅ Saved token type: $tokenType');

      // Calculate and save token expiry time
      final expiryTime = DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch;
      await prefs.setInt(TOKEN_EXPIRY_KEY, expiryTime);
      print('✅ Saved token expiry: $expiryTime');

      // Save user data as JSON string
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(USER_KEY, userJson);
      print('✅ Saved user data');

      // Save user ID separately for easy access
      await prefs.setInt(USER_ID_KEY, user.id);
      print('✅ Saved user ID: ${user.id}');

      // Save role names separately for easy access
      if (user.roleNames.isNotEmpty) {
        await prefs.setStringList(ROLES_KEY, user.roleNames);
        print('✅ Saved roles: ${user.roleNames}');
      } else {
        print('⚠️ No roles to save');
      }

      // Verify what was saved
      print('🔍 Verification:');
      print('🔍 Token saved: ${prefs.getString(TOKEN_KEY) != null}');
      print('🔍 User ID: ${prefs.getInt(USER_ID_KEY)}');
      print('🔍 User data saved: ${prefs.getString(USER_KEY) != null}');
      print('🔍 Roles: ${prefs.getStringList(ROLES_KEY)}');

      print('✅ saveAuthData completed successfully');
      return true;
    } catch (e) {
      print('❌ Error saving auth data: $e');
      return false;
    }
  }

  // Save auth data directly from API response format
  Future<bool> saveAuthDataFromResponse(
      Map<String, dynamic> responseData) async {
    try {
      print('🔄 Starting saveAuthDataFromResponse...');
      print('📥 Response data keys: ${responseData.keys}');

      final prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences instance obtained');

      // Save token
      if (responseData['token'] != null) {
        final token = responseData['token'] as String;
        await prefs.setString('token', token);
        print(
            '✅ Token saved with key "token": ${token.substring(0, Math.min(30, token.length))}...');
      } else {
        print('❌ No token found in response data');
      }

      // Save user data
      if (responseData['user'] != null) {
        final userJson = json.encode(responseData['user']);
        await prefs.setString('user', userJson);
        final userId = responseData['user']['id'];
        final userName = responseData['user']['name'];
        print('✅ User data saved with key "user": ID=$userId, Name=$userName');
      } else {
        print('❌ No user data found in response data');
      }

      // Save the full login response
      final fullResponse = json.encode(responseData);
      await prefs.setString('login_response', fullResponse);
      print('✅ Full login response saved with key "login_response"');

      // Verify what was actually saved
      print('🔍 Verification - saveAuthDataFromResponse:');
      final savedToken = prefs.getString('token');
      final savedUser = prefs.getString('user');
      final savedLoginResponse = prefs.getString('login_response');

      print('🔍 Saved token exists: ${savedToken != null}');
      print('🔍 Saved user exists: ${savedUser != null}');
      print('🔍 Saved login_response exists: ${savedLoginResponse != null}');

      if (savedUser != null) {
        try {
          final userData = json.decode(savedUser);
          print('🔍 Verified user ID from saved data: ${userData['id']}');
        } catch (e) {
          print('❌ Error parsing saved user data: $e');
        }
      }

      print('✅ saveAuthDataFromResponse completed successfully');
      return true;
    } catch (e) {
      print('❌ Error in saveAuthDataFromResponse: $e');
      return false;
    }
  }

  // Debug method to show all stored data
  Future<void> debugAllStoredData() async {
    try {
      print('🔍 ========== DEBUG: ALL STORED DATA ==========');
      final prefs = await SharedPreferences.getInstance();

      print('🔍 All SharedPreferences keys: ${prefs.getKeys()}');

      // Check all possible token keys
      final tokenKeys = ['token', 'auth_token'];
      for (final key in tokenKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          print(
              '🔍 $key: ${value.substring(0, Math.min(30, value.length))}...');
        } else {
          print('🔍 $key: null');
        }
      }

      // Check all possible user keys
      final userKeys = ['user', 'user_data'];
      for (final key in userKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          try {
            final userData = json.decode(value);
            print('🔍 $key: ID=${userData['id']}, Name=${userData['name']}');
          } catch (e) {
            print('🔍 $key: exists but parse error: $e');
          }
        } else {
          print('🔍 $key: null');
        }
      }

      // Check roles
      final rolesKeys = ['user_roles', 'roles'];
      for (final key in rolesKeys) {
        final value = prefs.getStringList(key);
        print('🔍 $key: $value');
      }

      // Check login response
      final loginResponse = prefs.getString('login_response');
      if (loginResponse != null) {
        try {
          final data = json.decode(loginResponse);
          print(
              '🔍 login_response: User ID=${data['user']?['id']}, Status=${data['status']}');
        } catch (e) {
          print('🔍 login_response: exists but parse error: $e');
        }
      } else {
        print('🔍 login_response: null');
      }

      // Check other keys
      final otherKeys = [
        'employee_data',
        'employee',
        'token_type',
        'token_expiry'
      ];
      for (final key in otherKeys) {
        final value = prefs.get(key);
        if (value != null) {
          print(
              '🔍 $key: ${value.toString().length > 50 ? '${value.toString().substring(0, 50)}...' : value}');
        } else {
          print('🔍 $key: null');
        }
      }

      print('🔍 ========== END DEBUG ==========');
    } catch (e) {
      print('❌ Error in debugAllStoredData: $e');
    }
  }

  // Get saved token
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final token = prefs.getString(TOKEN_KEY);

      // Check if token has expired
      final expiryTime = prefs.getInt(TOKEN_EXPIRY_KEY);
      if (expiryTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > expiryTime) {
          print('Token has expired, returning null');
          return null;
        }
      }

      return token;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  // Get token with type (for API headers)
  Future<String?> getFullToken() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final token = prefs.getString(TOKEN_KEY);
      final tokenType = prefs.getString(TOKEN_TYPE_KEY) ?? 'Bearer';

      if (token == null || token.isEmpty) return null;

      return '$tokenType $token';
    } catch (e) {
      print('Error retrieving full token: $e');
      return null;
    }
  }

  // Get saved user
  Future<UserModel?> getUser() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final userJson = prefs.getString(USER_KEY);

      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);

          // Load roles to ensure they're up to date
          final roles = prefs.getStringList(ROLES_KEY);
          if (roles != null && roles.isNotEmpty) {
            user.roles.clear();
            user.roles.addAll(roles
                .map((role) => RoleModel(id: 1, name: role, guardName: role)));
          }

          return user;
        } catch (e) {
          print('Error parsing saved user data: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error retrieving user: $e');
      return null;
    }
  }

  // Get employee data
  Future<Map<String, dynamic>?> getEmployeeData() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final employeeJson = prefs.getString(EMPLOYEE_KEY);

      if (employeeJson != null && employeeJson.isNotEmpty) {
        try {
          return jsonDecode(employeeJson) as Map<String, dynamic>;
        } catch (e) {
          print('Error parsing saved employee data: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error retrieving employee data: $e');
      return null;
    }
  }

  // Get user roles directly
  Future<List<String>> getUserRoles() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];

      final roles = prefs.getStringList(ROLES_KEY) ?? [];
      return roles;
    } catch (e) {
      print('Error retrieving roles: $e');
      return [];
    }
  }

  // Check if token is valid and not expired
  Future<bool> isTokenValid() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;

      final token = prefs.getString(TOKEN_KEY);
      if (token == null || token.isEmpty) return false;

      // Check expiry
      final expiryTime = prefs.getInt(TOKEN_EXPIRY_KEY);
      if (expiryTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        return now < expiryTime;
      }

      return true;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }

  // Clear all saved data on logout
  Future<bool> clearAll() async {
    try {
      print('🔄 Starting clearAll...');
      final prefs = await _getPrefs();
      if (prefs == null) {
        print('❌ Failed to get SharedPreferences for clearing');
        return false;
      }

      // Clear all auth-related keys
      final keysToRemove = [
        TOKEN_KEY,
        TOKEN_TYPE_KEY,
        TOKEN_EXPIRY_KEY,
        USER_KEY,
        ROLES_KEY,
        EMPLOYEE_KEY,
        'token',
        'user',
        'login_response',
        'roles',
        'employee'
      ];

      for (final key in keysToRemove) {
        await prefs.remove(key);
        print('✅ Removed key: $key');
      }

      // Verify clearing
      print('🔍 Verification after clearing:');
      for (final key in keysToRemove) {
        final value = prefs.get(key);
        print('🔍 $key: ${value == null ? 'cleared' : 'still exists!'}');
      }

      print('✅ All auth data cleared successfully');
      return true;
    } catch (e) {
      print('❌ Error clearing data: $e');
      return false;
    }
  }

  // Get all stored auth information in a single call
  Future<Map<String, dynamic>> getAllAuthData() async {
    final result = <String, dynamic>{};
    try {
      final prefs = await _getPrefs();
      print('SharedPreferences instance: $prefs');
      if (prefs == null) return result;

      // Get token data
      final token = prefs.getString(TOKEN_KEY);
      final tokenType = prefs.getString(TOKEN_TYPE_KEY);
      final expiryTime = prefs.getInt(TOKEN_EXPIRY_KEY);
      print([
        'Token:==============================> $token',
        'Token Type :Token:==============================>  $tokenType',
        'Expiry Time: $expiryTime',
      ]);

      result['token'] = token;
      result['tokenType'] = tokenType;
      result['tokenExpiry'] = expiryTime;

      if (token != null) {
        result['isTokenValid'] = expiryTime != null
            ? DateTime.now().millisecondsSinceEpoch < expiryTime
            : true;
      } else {
        result['isTokenValid'] = false;
      }

      // Get user data
      final userJson = prefs.getString(USER_KEY);
      if (userJson != null) {
        try {
          result['user'] = jsonDecode(userJson);
        } catch (e) {
          print('Error parsing user data in getAllAuthData: $e');
        }
      }

      // Get roles
      result['roles'] = prefs.getStringList(ROLES_KEY) ?? [];

      // Get employee data
      final employeeJson = prefs.getString(EMPLOYEE_KEY);
      if (employeeJson != null) {
        try {
          result['employee'] = jsonDecode(employeeJson);
        } catch (e) {
          print('Error parsing employee data in getAllAuthData: $e');
        }
      }

      return result;
    } catch (e) {
      print('Error retrieving all auth data: $e');
      return result;
    }
  }
}
