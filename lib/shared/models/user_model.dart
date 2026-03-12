import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/dealer_profile_model.dart';
import 'package:vidyarth_app/shared/models/profile_model.dart';

class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? phone;
  final UserRole role;
  final SubTier subTier;
  final DateTime? subExpiry;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final ProfileModel? profile;
  final DealerProfile? dealerProfile;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.phone,
    this.role = UserRole.STUDENT,
    this.subTier = SubTier.BASIC,
    this.subExpiry,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.profile,
    this.dealerProfile,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['user_id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      username: map['username'],
      isActive: map['is_active'] ?? true,
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      role: UserRole.values.firstWhere(
              (e) => e.name == map['role'],
          orElse: () => UserRole.STUDENT
      ),
      phone: map['phone'],
      subTier: SubTier.values.firstWhere((e) => e.name == map['sub_tier'], orElse: () => SubTier.BASIC),
      subExpiry: map['sub_expiry'] != null ? DateTime.parse(map['sub_expiry']) : null,
      profile: map['profiles'] != null ? ProfileModel.fromMap(map['profiles']) : null,
      dealerProfile: map['dealer_profiles'] != null ? DealerProfile.fromMap(map['dealer_profiles']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': id,
    'email': email,
    'username': username,
    'phone': phone,
    'role': role.name,
    'sub_tier': subTier.name,
    'sub_expiry': subExpiry?.toIso8601String(),
    'is_active': isActive,
  };
}