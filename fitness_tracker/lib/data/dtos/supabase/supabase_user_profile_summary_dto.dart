import '../../../domain/entities/user_profile_summary.dart';

class SupabaseUserProfileSummaryDto {
  const SupabaseUserProfileSummaryDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  factory SupabaseUserProfileSummaryDto.fromMap(Map<String, dynamic> map) {
    return SupabaseUserProfileSummaryDto(
      id: map['id'] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  UserProfileSummary toEntity() {
    return UserProfileSummary(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
