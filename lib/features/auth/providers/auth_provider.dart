import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _appUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = AppUser.fromFirestore(doc);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> signInWithEmailAndPassword(
    String email,
    String password, {
    UserRole? userRole,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);

        if (_appUser != null && userRole != null) {
          if (_appUser!.role != userRole) {
            await signOut();
            _error =
                'Invalid account type. Please select the correct user type.';
            return false;
          }
        }

        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    UserRole role,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final appUser = AppUser(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(appUser.toFirestore());

        _appUser = appUser;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _appUser = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile (display name and photo)
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user == null || _appUser == null) {
        _error = 'No user logged in';
        return false;
      }

      // Update Firebase Auth profile
      await _user!.updateDisplayName(displayName);
      if (photoUrl != null) {
        await _user!.updatePhotoURL(photoUrl);
      }

      // Update Firestore document
      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }
      updates['lastActive'] = DateTime.now();

      await _firestore.collection('users').doc(_user!.uid).update(updates);

      // Update local AppUser object
      _appUser = AppUser(
        id: _appUser!.id,
        email: _appUser!.email,
        displayName: displayName ?? _appUser!.displayName,
        photoUrl: photoUrl ?? _appUser!.photoUrl,
        phoneNumber: _appUser!.phoneNumber,
        role: _appUser!.role,
        trustLevel: _appUser!.trustLevel,
        trustScore: _appUser!.trustScore,
        friendIds: _appUser!.friendIds,
        createdAt: _appUser!.createdAt,
        lastActive: DateTime.now(),
        isVerified: _appUser!.isVerified,
        idVerified: _appUser!.idVerified,
        idVerificationDate: _appUser!.idVerificationDate,
        foodSafetyQACompleted: _appUser!.foodSafetyQACompleted,
        foodSafetyQADate: _appUser!.foodSafetyQADate,
        lastTrustScoreUpdate: _appUser!.lastTrustScoreUpdate,
        bio: _appUser!.bio,
        location: _appUser!.location,
        stats: _appUser!.stats,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
