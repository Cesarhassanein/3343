import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_config.dart';
import 'wadiq_api_service.dart';

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? bio;
  final String? avatarUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int likesCount;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.role = 'طالب',
    this.bio,
    this.avatarUrl,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.likesCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'role': role,
    'bio': bio,
    'avatar_url': avatarUrl,
    'posts_count': postsCount,
    'followers_count': followersCount,
    'following_count': followingCount,
    'likes_count': likesCount,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id']?.toString() ?? '',
    username: map['username']?.toString() ?? 'user',
    fullName: map['full_name']?.toString() ?? 'مستخدم ودق',
    role: map['role']?.toString() ?? 'طالب',
    bio: map['bio']?.toString(),
    avatarUrl: map['avatar_url']?.toString(),
    postsCount: (map['posts_count'] as num?)?.toInt() ?? 0,
    followersCount: (map['followers_count'] as num?)?.toInt() ?? 0,
    followingCount: (map['following_count'] as num?)?.toInt() ?? 0,
    likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
  );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserModel? _currentUser;
  UserModel get currentUser {
    return _currentUser ??
        UserModel(
          id: 'guest_id',
          username: 'wadiq_user',
          fullName: 'طالب جامعي',
          role: 'طالب',
          bio: 'طالب مسجل في منصة ودق الأكاديمية 🎓',
        );
  }

  bool get isAuthenticated => _currentUser != null && _currentUser!.id != 'guest_id';

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cleanVersion = prefs.getInt('wadiq_purge_test_accounts_v3');
    if (cleanVersion == null || cleanVersion < 3) {
      await prefs.remove('wadiq_registered_accounts');
      await prefs.remove('wadiq_user_session');
      await prefs.setInt('wadiq_purge_test_accounts_v3', 3);
      _currentUser = null;
      return;
    }

    final jsonStr = prefs.getString('wadiq_user_session');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr);
        if (map is Map<String, dynamic> && map['username'] != null) {
          _currentUser = UserModel.fromMap(map);
        }
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }
  }

  static String normalizeSignupRole(String role) {
    return 'طالب';
  }

  Future<List<Map<String, dynamic>>> _getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('wadiq_registered_accounts');
    if (str == null || str.isEmpty) return [];
    try {
      final list = jsonDecode(str);
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveStoredAccounts(List<Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wadiq_registered_accounts', jsonEncode(accounts));
  }

  Future<bool> isUsernameTaken(String username) async {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return false;

    // 1. Check backend auth store
    final existsInBackend = await WadiqApiService.instance.checkUserExists(clean);
    if (existsInBackend) return true;

    // 2. Check local registered accounts
    final accounts = await _getStoredAccounts();
    final existsLocally = accounts.any((a) => (a['username']?.toString().toLowerCase() ?? '') == clean);
    if (existsLocally) return true;

    // 3. Check Supabase profiles
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('profiles')
            .select('id')
            .eq('username', clean)
            .maybeSingle();
        if (res != null) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> isEmailTaken(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return false;

    final accounts = await _getStoredAccounts();
    return accounts.any((a) => (a['email']?.toString().toLowerCase() ?? '') == clean);
  }

  static bool isPasswordStrong(String password) {
    if (password.length < 6) return false;
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasLetter = RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(password);
    return hasNumber && hasLetter;
  }

  Future<bool> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    String? avatarUrl,
  }) {
    return register(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      role: role,
      avatarUrl: avatarUrl,
    );
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String role = 'طالب',
    String? avatarUrl,
  }) async {
    final cleanUsername = username.replaceAll('@', '').trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();
    final cleanFullName = fullName.trim();

    if (cleanFullName.isEmpty) {
      throw StateError('يرجى إدخال اسمك الكامل.');
    }

    if (cleanUsername.isEmpty) {
      throw StateError('يرجى إدخال اسم المستخدم.');
    }

    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw StateError('يرجى إدخال بريد إلكتروني صحيح.');
    }

    if (!isPasswordStrong(password)) {
      throw StateError('كلمة المرور يجب أن تكون قوية (6 خانات على الأقل، وتحتوي على أحرف وأرقام).');
    }

    // Check unique username
    if (await isUsernameTaken(cleanUsername)) {
      throw StateError('اسم المستخدم @$cleanUsername مستخدم مسبقاً، يرجى اختيار اسم آخر.');
    }

    // Check unique email
    if (await isEmailTaken(cleanEmail)) {
      throw StateError('البريد الإلكتروني مستخدم مسبقاً في حساب آخر.');
    }

    String userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userBio = 'طالب مسجل في منصة ودق الأكاديمية 🎓';

    // 1. Save in Backend Auth Store (authoritative UUID + scrypt password hashing + Supabase profile & credentials)
    try {
      final regRes = await WadiqApiService.instance.registerUser(
        fullName: cleanFullName,
        username: cleanUsername,
        email: cleanEmail,
        password: password.trim(),
        role: 'طالب',
        avatarUrl: avatarUrl,
      );
      if (regRes['success'] == true && regRes['user'] != null) {
        final serverUser = regRes['user'] as Map;
        if (serverUser['id'] != null) {
          userId = serverUser['id'].toString();
        }
      } else if (regRes['error'] != null) {
        throw StateError(regRes['error'].toString());
      }
    } catch (e) {
      if (e is StateError) rethrow;
      debugPrint('Backend auth registration note: $e');

      // Fallback: only if backend is unreachable, attempt direct Supabase profile insert
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('profiles').insert({
            'username': cleanUsername,
            'full_name': cleanFullName,
            'role': 'طالب',
            'avatar_url': avatarUrl,
            'bio': userBio,
          });
        } catch (subErr) {
          debugPrint('Supabase profile fallback insertion note: $subErr');
        }
      }
    }

    final newUser = UserModel(
      id: userId,
      username: cleanUsername,
      fullName: cleanFullName,
      role: 'طالب',
      bio: userBio,
      avatarUrl: avatarUrl,
    );

    // 3. Save in permanent local store with credentials
    final accounts = await _getStoredAccounts();
    accounts.removeWhere((a) => a['username'] == cleanUsername || a['email'] == cleanEmail);
    accounts.add({
      'id': userId,
      'username': cleanUsername,
      'email': cleanEmail,
      'full_name': cleanFullName,
      'role': 'طالب',
      'avatar_url': avatarUrl,
      'bio': userBio,
      'password': password.trim(),
    });
    await _saveStoredAccounts(accounts);

    // 4. Set current user and persist session
    _currentUser = newUser;
    await _persistSession();

    return true;
  }

  Future<bool> signIn({required String email, required String password}) {
    return login(usernameOrEmail: email, password: password);
  }

  Future<bool> login({required String usernameOrEmail, required String password}) async {
    final cleanInput = usernameOrEmail.replaceAll('@', '').trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanInput.isEmpty || cleanPassword.isEmpty) {
      throw StateError('يرجى إدخال اسم المستخدم/البريد الإلكتروني وكلمة المرور.');
    }

    // 1. Authoritative check via Backend Auth API (verifies password hash)
    try {
      final apiRes = await WadiqApiService.instance.loginUser(
        usernameOrEmail: cleanInput,
        password: cleanPassword,
      );

      if (apiRes['success'] == true && apiRes['user'] != null) {
        final userMap = Map<String, dynamic>.from(apiRes['user'] as Map);
        _currentUser = UserModel.fromMap(userMap);
        final accounts = await _getStoredAccounts();
        accounts.removeWhere((a) => a['username'] == _currentUser!.username);
        accounts.add({
          ..._currentUser!.toMap(),
          'email': userMap['email'] ?? (cleanInput.contains('@') ? cleanInput : '$cleanInput@wadiq.app'),
          'password': cleanPassword,
        });
        await _saveStoredAccounts(accounts);
        await _persistSession();
        return true;
      } else if (apiRes['error'] != null && apiRes['error'].toString().contains('كلمة المرور غير صحيحة')) {
        throw StateError('كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.');
      }
    } catch (e) {
      if (e is StateError) rethrow;
      debugPrint('Backend login attempt note: $e');
    }

    // 2. Check in locally stored registered accounts (strict password check)
    final accounts = await _getStoredAccounts();
    final localAccount = accounts.cast<Map<String, dynamic>?>().firstWhere(
      (a) =>
          a != null &&
          ((a['username']?.toString().toLowerCase() == cleanInput) ||
           (a['email']?.toString().toLowerCase() == cleanInput)),
      orElse: () => null,
    );

    if (localAccount != null) {
      final savedPassword = localAccount['password']?.toString() ?? '';
      if (savedPassword != cleanPassword) {
        throw StateError('كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.');
      }

      _currentUser = UserModel.fromMap(localAccount);
      await _persistSession();
      return true;
    }

    // User is NOT registered with this password
    throw StateError('الحساب غير موجود أو كلمة المرور غير مطابقة. يرجى التأكد من البيانات.');
  }

  Future<bool> resetPassword({
    required String usernameOrEmail,
    required String newPassword,
  }) async {
    final cleanInput = usernameOrEmail.replaceAll('@', '').trim().toLowerCase();
    final cleanPassword = newPassword.trim();

    if (cleanInput.isEmpty) {
      throw StateError('يرجى إدخال اسم المستخدم أو البريد الإلكتروني.');
    }

    if (!isPasswordStrong(cleanPassword)) {
      throw StateError('كلمة المرور الجديدة يجب أن تكون قوية (6 خانات على الأقل وتحتوي على أحرف وأرقام).');
    }

    final accounts = await _getStoredAccounts();
    final idx = accounts.indexWhere(
      (a) =>
          (a['username']?.toString().toLowerCase() == cleanInput) ||
          (a['email']?.toString().toLowerCase() == cleanInput),
    );

    if (idx == -1) {
      // Check if user exists in Supabase
      final client = SupabaseConfig.client;
      if (client != null) {
        final res = await client
            .from('profiles')
            .select('*')
            .eq('username', cleanInput)
            .maybeSingle();
        if (res != null) {
          accounts.add({
            ...res,
            'email': '$cleanInput@wadiq.app',
            'password': cleanPassword,
          });
          await _saveStoredAccounts(accounts);
          return true;
        }
      }
      throw StateError('لم يتم العثور على أي حساب مسجل بهذا الاسم أو البريد.');
    }

    accounts[idx]['password'] = cleanPassword;
    await _saveStoredAccounts(accounts);
    return true;
  }

  Future<void> updateProfile({required String fullName, required String bio, String? avatarUrl}) async {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      username: _currentUser!.username,
      fullName: fullName,
      role: _currentUser!.role,
      bio: bio,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      followersCount: _currentUser!.followersCount,
      followingCount: _currentUser!.followingCount,
      likesCount: _currentUser!.likesCount,
    );
    await _persistSession();

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final updateMap = <String, dynamic>{'full_name': fullName, 'bio': bio};
        if (avatarUrl != null) updateMap['avatar_url'] = avatarUrl;
        await client
            .from('profiles')
            .update(updateMap)
            .eq('username', _currentUser!.username);
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wadiq_user_session');
    await WadiqApiService.instance.logoutUser();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final clean = query.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return [];

    final Map<String, UserModel> results = {};

    // 1. Search Supabase profiles
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('profiles')
            .select('*')
            .ilike('username', '%$clean%')
            .limit(10);
        for (var item in (res as List<dynamic>)) {
          final u = UserModel.fromMap(item as Map<String, dynamic>);
          results[u.username.toLowerCase()] = u;
        }
      } catch (e) {
        debugPrint('Search users DB note: $e');
      }
    }

    // 2. Search local registered accounts
    final accounts = await _getStoredAccounts();
    for (var a in accounts) {
      final uname = a['username']?.toString().toLowerCase() ?? '';
      final fname = a['full_name']?.toString().toLowerCase() ?? '';
      if (uname.contains(clean) || fname.contains(clean)) {
        if (!results.containsKey(uname)) {
          results[uname] = UserModel.fromMap(a);
        }
      }
    }

    return results.values.toList();
  }

  Future<void> _persistSession() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wadiq_user_session', jsonEncode(_currentUser!.toMap()));
  }
}
