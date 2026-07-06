import 'dart:convert';
import 'dart:io';

import 'package:auth0_flutter/auth0_flutter.dart' as auth0;
import 'package:auth0_flutter/auth0_flutter_web.dart' as auth0_web;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:adopet/features/profile/models/user_profile.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static const _sessionKey = 'auth_session';

  Database? _db;
  UserProfile? currentUser;
  auth0.Auth0? _auth0;
  auth0_web.Auth0Web? _auth0Web;

  Future<void> initialize() async {
    if (kIsWeb) {
      _auth0Web = auth0_web.Auth0Web('dev-jzwhcfe325islwqz.us.auth0.com', 'O8SiIN38jquZ3FWghtWzSE676DwQ7EAb');
      await _auth0Web?.onLoad();
    } else {
      _auth0 = auth0.Auth0('dev-jzwhcfe325islwqz.us.auth0.com', 'O8SiIN38jquZ3FWghtWzSE676DwQ7EAb');
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _db = await openDatabase(
        'adopet.db',
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              passwordHash TEXT NOT NULL,
              dob TEXT,
              contact_number TEXT,
              cep TEXT,
              city TEXT,
              state TEXT,
              preferences TEXT NOT NULL DEFAULT '',
              favorites TEXT NOT NULL DEFAULT '',
              createdAt TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 4) {
            await db.execute('ALTER TABLE users ADD COLUMN dob TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN contact_number TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN cep TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN city TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN state TEXT');
          }
        },
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      currentUser = UserProfile.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? preferences,
    String? favorites,
    String? dob,
    String? contactNumber,
    String? cep,
    String? city,
    String? state,
  }) async {
    if (currentUser == null) return false;

    final updatedUser = UserProfile(
      id: currentUser!.id,
      name: name.trim(),
      email: currentUser!.email,
      passwordHash: currentUser!.passwordHash,
      dob: dob ?? currentUser!.dob,
      contactNumber: contactNumber ?? currentUser!.contactNumber,
      cep: cep ?? currentUser!.cep,
      city: city ?? currentUser!.city,
      state: state ?? currentUser!.state,
      preferences: preferences ?? currentUser!.preferences,
      favorites: favorites ?? currentUser!.favorites,
      createdAt: currentUser!.createdAt,
    );

    if (_db != null) {
      await _db!.update('users', updatedUser.toJson(), where: 'id = ?', whereArgs: [updatedUser.id]);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_${updatedUser.id}', jsonEncode(updatedUser.toJson()));
    }

    await _persistSession(updatedUser);
    currentUser = updatedUser;
    return true;
  }

  Future<bool> toggleFavorite(String petId) async {
    if (currentUser == null) return false;

    List<String> currentFavs = currentUser!.favorites
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    if (currentFavs.contains(petId)) {
      currentFavs.remove(petId);
    } else {
      currentFavs.add(petId);
    }

    final newFavoritesString = currentFavs.join(',');

    return await updateProfile(
      name: currentUser!.name,
      favorites: newFavoritesString,
    );
  }

  Future<bool> loginWithAuth0() async {
    try {
      auth0.Credentials credentials;

      if (kIsWeb) {
        credentials = await _auth0Web!.loginWithPopup();
      } else {
        credentials = await _auth0!.webAuthentication().login();
      }

      final auth0User = credentials.user;
      final normalizedEmail = auth0User.email?.trim().toLowerCase() ?? '';

      var localUser = await _findUser(auth0User.sub);

      if (localUser == null) {

        String nameFromEmail = normalizedEmail.contains('@') 
            ? normalizedEmail.split('@')[0] 
            : 'Novo Usuário';
        
        String displayName = auth0User.name?.trim() ?? '';
        
        if (displayName.isEmpty || displayName.toLowerCase() == normalizedEmail) {
          displayName = nameFromEmail;
        }

        localUser = UserProfile(
          id: auth0User.sub,
          name: displayName,
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
        await prefs.setString('user_${auth0User.sub}', jsonEncode(localUser.toJson()));
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
      if (kIsWeb) {
        await _auth0Web!.logout(returnToUrl: 'http://localhost:3000');
      } else {
        await _auth0!.webAuthentication().logout();
      }
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

  Future<UserProfile?> _findUser(String auth0Id) async {
    if (_db != null) {
      final rows = await _db!.query('users', where: 'id = ?', whereArgs: [auth0Id], limit: 1);
      if (rows.isNotEmpty) return UserProfile.fromJson(rows.first.cast<String, dynamic>());
    } else {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_$auth0Id');
      if (userData != null) {
        return UserProfile.fromJson(jsonDecode(userData) as Map<String, dynamic>);
      }
    }
    return null;
  }
}