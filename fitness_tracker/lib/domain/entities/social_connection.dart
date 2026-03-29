import 'package:equatable/equatable.dart';

/// Represents a single follow relationship between two users.
class SocialConnection extends Equatable {
  const SocialConnection({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  final String followerId;
  final String followingId;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[followerId, followingId, createdAt];
}
