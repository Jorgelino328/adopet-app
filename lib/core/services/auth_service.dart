import 'dart:convert';
import 'dart:io';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.preferences,
    this.age,
    this.favorites = '',
    required this.createdAt,
  });

  static const petPreferenceOptions = ['dog', 'cat', 'bird', 'other'];

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String preferences;
  final int? age;
  final String favorites;
  final DateTime createdAt;

factory UserProfile.fromJson(Map<String, dynamic> json) {
  return UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String,
    preferences: json['preferences'] as String,
    age: json['age'] is String ? int.tryParse(json['age']) : json['age'] as int?,
    favorites: json['favorites'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, dynamic> toJson() {
  return {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'preferences': preferences,
    'age': age,
    'favorites': favorites,
    'createdAt': createdAt.toIso8601String(),
  };
}

  static List<String> parsePreferenceSelections(String preferences) {
    return preferences
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String serializePreferenceSelections(List<String> selections) {
    return selections
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .join(',');
  }

  static String labelForPreference(String value) {
    switch (value.toLowerCase()) {
      case 'dog':
        return 'Cachorro';
      case 'cat':
        return 'Gato';
      case 'bird':
        return 'Pássaro';
      case 'other':
      default:
        return 'Outro';
    }
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _sessionKey = 'auth_session';

  Database? _db;
  UserProfile? currentUser;
  late Auth0 _auth0;

  Future<void> initialize() async {
    _auth0 = Auth0('dev-jzwhcfe325islwqz.us.auth0.com', 'O8SiIN38jquZ3FWghtWzSE676DwQ7EAb');
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _db = await openDatabase(
        'adopet.db',
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              passwordHash TEXT NOT NULL,
              preferences TEXT NOT NULL,
              age INTEGER,
              favorites TEXT NOT NULL DEFAULT '',
              createdAt TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE users ADD COLUMN age INTEGER');
            await db.execute('ALTER TABLE users ADD COLUMN favorites TEXT NOT NULL DEFAULT ""');
          }
        },
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      currentUser = UserProfile.fromJson(
        jsonDecode(sessionJson) as Map<String, dynamic>,
      );
    }
  }

Future<bool> updateProfile({
    required String name,
    required String email, // Keep the parameter to avoid breaking ProfilePage
    required String preferences,
    int? age,
    String? favorites,
  }) async {
    if (currentUser == null) return false;

    final updatedUser = UserProfile(
      id: currentUser!.id,
      name: name.trim(),
      email: currentUser!.email,
      passwordHash: currentUser!.passwordHash,
      preferences: preferences.trim(),
      age: age,
      favorites: favorites ?? currentUser!.favorites,
      createdAt: currentUser!.createdAt,
    );

    if (_db != null) {
      await _db!.update(
        'users',
        updatedUser.toJson(),
        where: 'id = ?',
        whereArgs: [updatedUser.id],
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${updatedUser.email}', jsonEncode(updatedUser.toJson()));
    await _persistSession(updatedUser);
    currentUser = updatedUser;
    return true;
  }

  Future<bool> loginWithAuth0() async {
    try {
      final credentials = await _auth0.webAuthentication().login(useHTTPS: true);
      final auth0User = credentials.user;
      final normalizedEmail = auth0User.email?.trim().toLowerCase() ?? '';

      var localUser = await _findUser(normalizedEmail);

      if (localUser == null) {
        localUser = UserProfile(
          id: auth0User.sub,
          name: auth0User.name ?? 'Novo Usuário',
          email: normalizedEmail,
          passwordHash: 'managed_by_auth0',
          preferences: '',
          favorites: '',
          createdAt: DateTime.now(),
        );

        if (_db != null) {
          await _db!.insert('users', localUser.toJson());
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_$normalizedEmail', jsonEncode(localUser.toJson()));
      }

      await _persistSession(localUser);
      currentUser = localUser;
      return true;
    } catch (e) {
      if (kDebugMode) print('Auth0 Login Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth0.webAuthentication().logout(useHTTPS: true);
    } catch (e) {
      if (kDebugMode) print('Auth0 Logout Error: $e');
    }
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> clearForTests() async {
    if (_db != null) await _db!.delete('users');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    currentUser = null;
  }

  Future<void> _persistSession(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<UserProfile?> _findUser(String email) async {
    if (_db != null) {
      final rows = await _db!.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
      if (rows.isNotEmpty) return UserProfile.fromJson(rows.first.cast<String, dynamic>());
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user_$email');
    return stored != null ? UserProfile.fromJson(jsonDecode(stored)) : null;
  }
}