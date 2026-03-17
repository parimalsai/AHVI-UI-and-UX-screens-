import 'package:flutter/foundation.dart';

class AuthUserData {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? uid;

  const AuthUserData({
    this.displayName,
    this.email,
    this.photoUrl,
    this.uid,
  });
}

class AuthUserController extends ChangeNotifier {
  AuthUserData _user = const AuthUserData();

  AuthUserData get user => _user;

  void setFromProvider({
    String? displayName,
    String? email,
    String? photoUrl,
    String? uid,
  }) {
    _user = AuthUserData(
      displayName: _normalize(displayName),
      email: _normalize(email),
      photoUrl: _normalize(photoUrl),
      uid: _normalize(uid),
    );
    notifyListeners();
  }

  void clear() {
    _user = const AuthUserData();
    notifyListeners();
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
