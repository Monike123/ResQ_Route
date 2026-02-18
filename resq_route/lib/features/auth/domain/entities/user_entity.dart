import 'package:equatable/equatable.dart';

/// Domain entity representing a user.
class UserEntity extends Equatable {
  final String id;
  final String? phone;
  final String? email;
  final String? fullName;
  final String? gender;
  final String? profileImageUrl;
  final String verificationStatus;
  final bool onboardingCompleted;

  const UserEntity({
    required this.id,
    this.phone,
    this.email,
    this.fullName,
    this.gender,
    this.profileImageUrl,
    this.verificationStatus = 'pending',
    this.onboardingCompleted = false,
  });

  bool get isVerified => verificationStatus == 'verified';

  @override
  List<Object?> get props => [id, phone, email, verificationStatus];
}
