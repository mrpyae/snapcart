import '../local/user_dao.dart';
import '../models/user_model.dart';
import '../providers/api_provider.dart';

class AuthRepository {
  final ApiProvider apiProvider = ApiProvider();
  final UserDao userDao = UserDao();

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    bool forceOffline = false,
    bool disallowOfflineFallback = false,
  }) async {
    // 1. Try Online Login first only if not forced offline
    if (!forceOffline) {
      try {
        final onlineRes = await apiProvider.login(username, password).timeout(const Duration(seconds: 4));

        if (onlineRes['status'] == 'success' && onlineRes['data'] != null) {
          final user = UserModel.fromJson(onlineRes['data']);
          // Cache user and accounts asynchronously without blocking the user response
          userDao.cacheUsersAndAccounts([user.toMap()], user.accounts.map((a) => a.toMap()).toList()).catchError((_) => null);
          return {
            'success': true,
            'user': user,
            'mode': 'online',
          };
        } else if (disallowOfflineFallback) {
          return {
            'success': false,
            'message': onlineRes['message'] ?? 'Online authentication failed',
          };
        }
      } catch (e) {
        if (disallowOfflineFallback) {
          return {
            'success': false,
            'message': 'Cannot reach online server in Online Only mode ($e)',
          };
        }
        // Server unreachable, fallback to offline
      }
    }

    if (disallowOfflineFallback) {
      return {
        'success': false,
        'message': 'Online login required in Online Only mode',
      };
    }

    // 2. Fallback to Offline Local SQLite Login (Instant)
    try {
      final offlineUser = await userDao.getOfflineUserByUsername(username);
      if (offlineUser != null) {
        final isPasswordValid = await userDao.verifyOfflinePassword(offlineUser.id, password);
        if (isPasswordValid) {
          return {
            'success': true,
            'user': offlineUser,
            'mode': 'offline',
          };
        } else {
          return {
            'success': false,
            'message': 'Incorrect offline password.',
          };
        }
      }
    } catch (_) {}

    return {
      'success': false,
      'message': 'Invalid username or password. (admin / 123456)',
    };
  }

  Future<UserAccountModel?> verifyPin(String accountId, String pin) async {
    // 1. Local Check (Instant)
    try {
      final localAcc = await userDao.verifyOfflinePin(accountId, pin);
      if (localAcc != null) return localAcc;
    } catch (_) {}

    // 2. Remote check if local failed
    try {
      final remoteRes = await apiProvider.verifyPin(accountId, pin).timeout(const Duration(seconds: 3));
      if (remoteRes['status'] == 'success' && remoteRes['data'] != null) {
        return UserAccountModel.fromJson(remoteRes['data']);
      }
    } catch (_) {}

    return null;
  }
}
