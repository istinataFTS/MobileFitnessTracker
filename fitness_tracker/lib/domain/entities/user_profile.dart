import 'package:equatable/equatable.dart';

/// Server-owned profile for an authenticated user.
/// [id] always matches the Supabase `auth.users.id` for this account.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Primary key — same UUID as the Supabase auth user.
  final String id;

  /// Unique handle chosen at registration. Treated as immutable after creation.
  final String username;

  /// Human-readable name shown in the UI (editable).
  final String? displayName;

  /// Short bio shown on the profile page (editable).
  final String? bio;

  /// URL of the user's avatar image (editable).
  final String? avatarUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? username,
    String? displayName,
    bool clearDisplayName = false,
    String? bio,
    bool clearBio = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName:
          clearDisplayName ? null : (displayName ?? this.displayName),
      bio: clearBio ? null : (bio ?? this.bio),
      avatarUrl:
          clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        username,
        displayName,
        bio,
        avatarUrl,
        createdAt,
        updatedAt,
      ];
}
