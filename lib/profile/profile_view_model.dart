import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../auth/auth_session_manager.dart';
import '../constants/firebase_constants.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({FirebaseFirestore? firestore, ImagePicker? imagePicker})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _imagePicker = imagePicker ?? ImagePicker();

  final FirebaseFirestore _firestore;
  final ImagePicker _imagePicker;

  bool _isLoading = true;
  bool _isUploadingProfilePic = false;
  String? _errorMessage;
  String _name = 'Guest User';
  String _username = 'guest_user';
  String _userId = '-';
  String _profilePic = '';
  bool _isOnline = false;

  bool get isLoading => _isLoading;
  bool get isUploadingProfilePic => _isUploadingProfilePic;
  String? get errorMessage => _errorMessage;
  String get screenTitle => 'Profile';
  String get name => _name;
  String get username => _username;
  String get userId => _userId;
  String get profilePic => _profilePic;
  bool get isOnline => _isOnline;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? sessionName = await AuthSessionManager.getName();
      final String? sessionUsername = await AuthSessionManager.getUsername();
      final String? sessionUserId = await AuthSessionManager.getUserId();

      _name = (sessionName == null || sessionName.trim().isEmpty)
          ? 'Guest User'
          : sessionName.trim();
      _username = (sessionUsername == null || sessionUsername.trim().isEmpty)
          ? 'guest_user'
          : sessionUsername.trim();
      _userId = (sessionUserId == null || sessionUserId.trim().isEmpty)
          ? '-'
          : sessionUserId.trim();

      if (_userId != '-') {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection(FirebaseCollections.users)
            .doc(_userId)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          final Map<String, dynamic> data = snapshot.data()!;
          _name =
              (data[FirebaseFields.name] as String?)?.trim().isNotEmpty == true
              ? (data[FirebaseFields.name] as String).trim()
              : _name;
          _username =
              (data[FirebaseFields.username] as String?)?.trim().isNotEmpty ==
                  true
              ? (data[FirebaseFields.username] as String).trim()
              : _username;
          _profilePic =
              (data[FirebaseFields.profilePic] as String?)?.trim() ?? '';
          _isOnline = (data[FirebaseFields.isOnline] as bool?) ?? false;
        }
      }
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Unable to load profile.';
    } catch (_) {
      _errorMessage = 'Unable to load profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfilePictureFromGallery() async {
    final bool hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      return 'Gallery permission is required. Please allow it in settings.';
    }

    return _pickAndUpload(source: ImageSource.gallery);
  }

  Future<String?> updateProfilePictureFromCamera() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!(status.isGranted || status.isLimited)) {
      return 'Camera permission is required. Please allow it in settings.';
    }

    return _pickAndUpload(source: ImageSource.camera);
  }

  Future<bool> _requestGalleryPermission() async {
    final PermissionStatus photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }

    final PermissionStatus storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  Future<String?> _pickAndUpload({required ImageSource source}) async {
    if (_userId == '-' || _userId.isEmpty) {
      return 'User not found. Please sign in again.';
    }

    _isUploadingProfilePic = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 720,
      );

      if (file == null) {
        return null;
      }

      final List<int> bytes = await file.readAsBytes();
      final String base64Image = base64Encode(bytes);

      if (base64Image.length > 900000) {
        return 'Image is too large. Please choose a smaller image.';
      }

      await _firestore.collection(FirebaseCollections.users).doc(_userId).set({
        FirebaseFields.profilePic: base64Image,
      }, SetOptions(merge: true));

      _profilePic = base64Image;
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to update profile picture.';
    } catch (_) {
      return 'Unable to update profile picture.';
    } finally {
      _isUploadingProfilePic = false;
      notifyListeners();
    }
  }
}
