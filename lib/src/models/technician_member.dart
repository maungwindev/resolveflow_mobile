import 'package:equatable/equatable.dart';

/// Represents a technician user in the organization.
class TechnicianMember extends Equatable {
  const TechnicianMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.roles = const ['technician'],
    this.joinedAt,
    this.isConfirmed = true,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;
  final DateTime? joinedAt;
  final bool isConfirmed;
  final bool isActive;

  factory TechnicianMember.fromJson(Map<String, dynamic> json) {
    DateTime? joined;
    if (json['joined'] != null) {
      joined = DateTime.tryParse(json['joined'].toString());
    } else if (json['\$createdAt'] != null) {
      joined = DateTime.tryParse(json['\$createdAt'].toString());
    }

    final rawRoles = json['roles'];
    final rolesList = rawRoles is List
        ? rawRoles.map((e) => e.toString()).toList()
        : const <String>['technician'];

    final phoneVal = json['userPhone']?.toString() ??
        json['phone']?.toString();

    final rawLabels = json['labels'];
    final isLabeledInactive = rawLabels is List && rawLabels.contains('inactive');
    final bool active = json['status'] == false || isLabeledInactive ? false : true;

    return TechnicianMember(
      id: json['\$id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['\$id']?.toString() ?? '',
      name: json['userName']?.toString() ?? json['name']?.toString() ?? 'Technician',
      email: json['userEmail']?.toString() ?? json['email']?.toString() ?? '',
      phone: (phoneVal != null && phoneVal.isNotEmpty) ? phoneVal : null,
      roles: rolesList,
      joinedAt: joined ?? DateTime.now(),
      isConfirmed: json['confirm'] == true,
      isActive: active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'roles': roles,
        'joinedAt': joinedAt?.toIso8601String(),
        'isConfirmed': isConfirmed,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [id, userId, name, email, phone, roles, joinedAt, isConfirmed, isActive];
}
