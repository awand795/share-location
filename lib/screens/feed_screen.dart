import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/story_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndPostStory() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      _showStoryDialog(image);
    }
  }

  void _showStoryDialog(XFile image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Story'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(image.path), height: 200),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Caption',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _postStory(image);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _postStory(XFile image) async {
    setState(() => _isPosting = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Upload image to Firebase Storage
      String fileName = '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('stories/$fileName');
      
      UploadTask uploadTask = storageRef.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Create story document
      StoryModel story = StoryModel(
        id: FirebaseFirestore.instance.collection('stories').doc().id,
        userId: currentUser.uid,
        imageUrl: imageUrl,
        caption: _captionController.text.trim(),
        createdAt: DateTime.now(),
        likes: [],
      );

      await FirebaseFirestore.instance
          .collection('stories')
          .doc(story.id)
          .set(story.toMap());

      _captionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story posted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting story: ${e.toString()}')),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  Future<void> _likeStory(String storyId, List<String> currentLikes) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (currentLikes.contains(currentUser.uid)) {
        // Unlike
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .update({
          'likes': FieldValue.arrayRemove([currentUser.uid])
        });
      } else {
        // Like
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .update({
          'likes': FieldValue.arrayUnion([currentUser.uid])
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking story: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isPosting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _pickImageAndPostStory,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No stories yet', style: TextStyle(fontSize: 18)),
                  Text('Be the first to share a story!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              StoryModel story = StoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

              return StoryCard(
                story: story,
                onLike: () => _likeStory(story.id, story.likes),
              );
            },
          );
        },
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onLike;

  const StoryCard({
    super.key,
    required this.story,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    bool isLiked = currentUser != null && story.likes.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(story.userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const ListTile(
                  title: Text('Unknown User'),
                  subtitle: Text('Loading...'),
                );
              }

              Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
              String userName = userData['name'] ?? 'Unknown User';

              return ListTile(
                leading: CircleAvatar(
                  child: Text(userName[0].toUpperCase()),
                ),
                title: Text(userName),
                subtitle: Text(_formatDate(story.createdAt)),
              );
            },
          ),
          if (story.imageUrl.isNotEmpty)
            Image.network(
              story.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                );
              },
            ),
          if (story.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(story.caption),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: onLike,
                ),
                Text('${story.likes.length} likes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
