import 'package:equatable/equatable.dart';

/// Domain user entity. Parsing belongs in factories / data mappers.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.teams = const [],
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final List<String> teams;

  bool get isTechnician => teams.contains('technicians');
  bool get isManager => teams.contains('managers');

  factory AppUser.empty() => const AppUser(id: '', email: '');

  /// Null-safe JSON factory with map pattern matching.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teams'];
    final teamsList = rawTeams is List
        ? rawTeams.map((e) => e.toString()).toList()
        : const <String>[];

    return switch (json) {
      {
        'id': final Object? id,
        'email': final Object? email,
      } =>
        AppUser(
          id: id?.toString() ?? '',
          email: email?.toString() ?? '',
          name: json['name']?.toString(),
          photoUrl: json['photoUrl']?.toString(),
          teams: teamsList,
        ),
      _ => AppUser.empty(),
    };
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'teams': teams,
      };

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [id, email, name, photoUrl, teams];
}
