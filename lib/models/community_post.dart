class CommunityPost {
  final String id;
  final String username;
  final String profileImage;
  final String content;
  final DateTime timestamp;
  int likes;
  int comments;

  CommunityPost({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });
}
