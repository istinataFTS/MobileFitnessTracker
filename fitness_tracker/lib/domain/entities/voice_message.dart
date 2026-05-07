import 'package:equatable/equatable.dart';

enum VoiceRole { user, assistant }

class VoiceMessage extends Equatable {
  const VoiceMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final VoiceRole role;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[role, content, createdAt];
}
