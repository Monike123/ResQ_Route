import 'package:equatable/equatable.dart';

/// User profile model for Supabase `user_profiles` table.
class UserProfileModel extends Equatable {
  final String id;
  final String? phone;
  final String? email;
  final String? fullName;
  final String? gender;
  final String? profileImageUrl;
  final String verificationStatus;
  final String? verificationType;
  final String preferredEmergencyLanguage;
  final double trustScore;
  final bool isActive;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    this.phone,
    this.email,
    this.fullName,
    this.gender,
    this.profileImageUrl,
    this.verificationStatus = 'pending',
    this.verificationType,
    this.preferredEmergencyLanguage = 'en',
    this.trustScore = 0.0,
    this.isActive = true,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      verificationStatus:
          (json['verification_status'] as String?) ?? 'pending',
      verificationType: json['verification_type'] as String?,
      preferredEmergencyLanguage:
          (json['preferred_emergency_language'] as String?) ?? 'en',
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
      isActive: (json['is_active'] as bool?) ?? true,
      onboardingCompleted: (json['onboarding_completed'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'full_name': fullName,
        'gender': gender,
        'profile_image_url': profileImageUrl,
        'verification_status': verificationStatus,
        'verification_type': verificationType,
        'preferred_emergency_language': preferredEmergencyLanguage,
        'trust_score': trustScore,
        'is_active': isActive,
        'onboarding_completed': onboardingCompleted,
      };

  /// Create a copy with updated fields.
  UserProfileModel copyWith({
    String? fullName,
    String? gender,
    String? profileImageUrl,
    String? verificationStatus,
    String? verificationType,
    String? preferredEmergencyLanguage,
    bool? onboardingCompleted,
  }) {
    return UserProfileModel(
      id: id,
      phone: phone,
      email: email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationType: verificationType ?? this.verificationType,
      preferredEmergencyLanguage:
          preferredEmergencyLanguage ?? this.preferredEmergencyLanguage,
      trustScore: trustScore,
      isActive: isActive,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id, phone, email, fullName, gender, verificationStatus,
        onboardingCompleted,
      ];
}
