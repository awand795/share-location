import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final List<String> likes;

  StoryModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.likes,
  });

  // Create from Firestore document
  factory StoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StoryModel(
      id: documentId,
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }

  // Create copy with updated values
  StoryModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    List<String>? likes,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }

  @override
  String toString() {
    return 'StoryModel(id: $id, userId: $userId, caption: $caption, likes: ${likes.length})';
  }
}
