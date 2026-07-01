import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
    required this.existingPets,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String preferences;
  final String existingPets;
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      preferences: json['preferences'] as String,
      existingPets: json['existingPets'] as String,
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
      'existingPets': existingPets,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _sessionKey = 'auth_session';

  Database? _db;
  UserProfile? currentUser;

  Future<void> initialize() async {
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _db = await openDatabase(
        'pet_shop.db',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              passwordHash TEXT NOT NULL,
              preferences TEXT NOT NULL,
              existingPets TEXT NOT NULL,
              createdAt TEXT NOT NULL
            )
          ''');
        },
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      currentUser = UserProfile.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String preferences,
    required String existingPets,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (await _userExists(normalizedEmail)) {
      return false;
    }

    final user = UserProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hashPassword(password),
      preferences: preferences.trim(),
      existingPets: existingPets.trim(),
      createdAt: DateTime.now(),
    );

    if (_db != null) {
      await _db!.insert('users', user.toJson());
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${user.email}', jsonEncode(user.toJson()));
    await _persistSession(user);
    currentUser = user;
    return true;
  }

  Future<UserProfile?> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final parsedUser = await _findUser(normalizedEmail);
    if (parsedUser == null) {
      return null;
    }

    if (_hashPassword(password) != parsedUser.passwordHash) {
      return null;
    }

    await _persistSession(parsedUser);
    currentUser = parsedUser;
    return parsedUser;
  }

  Future<void> signOut() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> clearForTests() async {
    if (_db != null) {
      await _db!.delete('users');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    currentUser = null;
  }

  String _hashPassword(String password) {
    final salt = 'petshop-salt-v1';
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _persistSession(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<bool> _userExists(String email) async {
    final user = await _findUser(email);
    return user != null;
  }

  Future<UserProfile?> _findUser(String email) async {
    if (_db != null) {
      final rows = await _db!.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return UserProfile.fromJson(rows.first.cast<String, dynamic>());
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user_$email');
    if (stored != null) {
      return UserProfile.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    }
    return null;
  }
}
