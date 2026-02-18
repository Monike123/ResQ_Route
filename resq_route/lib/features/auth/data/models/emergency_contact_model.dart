import 'package:equatable/equatable.dart';

/// Emergency contact model for Supabase `emergency_contacts` table.
class EmergencyContactModel extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String phone;
  final int priority; // 1-5
  final String? relationship;
  final bool isVerified;

  const EmergencyContactModel({
    this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.priority,
    this.relationship,
    this.isVerified = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      priority: json['priority'] as int,
      relationship: json['relationship'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'phone': phone,
        'priority': priority,
        'relationship': relationship,
      };

  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    int? priority,
    String? relationship,
    bool? isVerified,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
      relationship: relationship ?? this.relationship,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, phone, priority];
}
