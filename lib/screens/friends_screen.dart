import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != currentUser.uid)
          .toList();

      // Filter out users who are already friends or have pending requests
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      QuerySnapshot sentRequestsSnapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentUser.uid)
          .get();

      Set<String> existingFriendIds = friendsSnapshot.docs
          .map((doc) => doc['friendId'] as String)
          .toSet();

      Set<String> sentRequestIds = sentRequestsSnapshot.docs
          .map((doc) => doc['receiverId'] as String)
          .toSet();

      setState(() {
        _searchResults = users
            .where(
              (user) =>
                  !existingFriendIds.contains(user.uid) &&
                  !sentRequestIds.contains(user.uid),
            )
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendFriendRequest(UserModel user) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      FriendRequestModel request = FriendRequestModel(
        id: FirebaseFirestore.instance.collection('friend_requests').doc().id,
        senderId: currentUser.uid,
        receiverId: user.uid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(request.id)
          .set(request.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${user.name}')),
      );

      // Refresh search results
      _searchUsers(_searchController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: ${e.toString()}')),
      );
    }
  }

  Future<void> _acceptFriendRequest(String requestId, String senderId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update request status
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Add friendship for both users
      await FirebaseFirestore.instance.collection('friends').add({
        'userId': currentUser.uid,
        'friendId': senderId,
        'createdAt': DateTime.now(),
      });

      await FirebaseFirestore.instance.collection('friends').add({
        'userId': senderId,
        'friendId': currentUser.uid,
        'createdAt': DateTime.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request accepted!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request rejected')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: ${e.toString()}')),
      );
    }
  }

  Future<void> _unfriendUser(String friendId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      QuerySnapshot friendships = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId', isEqualTo: currentUser.uid)
          .where('friendId', isEqualTo: friendId)
          .get();

      QuerySnapshot reverseFriendships = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId', isEqualTo: friendId)
          .where('friendId', isEqualTo: currentUser.uid)
          .get();

      // Delete all friendship documents
      for (var doc in friendships.docs) {
        await doc.reference.delete();
      }

      for (var doc in reverseFriendships.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend removed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing friend: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildFriendRequests(),
          _buildFindFriends(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Please login'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friends')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No friends yet', style: TextStyle(fontSize: 18)),
                Text('Find friends to share your location with!'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            String friendId = doc['friendId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
              builder: (context, friendSnapshot) {
                if (friendSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text('Loading...'));
                }

                if (!friendSnapshot.hasData || !friendSnapshot.data!.exists) {
                  return const ListTile(title: Text('Unknown User'));
                }

                UserModel friend = UserModel.fromMap(
                  friendSnapshot.data!.data() as Map<String, dynamic>,
                );

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(friend.name[0].toUpperCase()),
                  ),
                  title: Text(friend.name),
                  subtitle: friend.isOnline
                      ? const Text(
                          'Online',
                          style: TextStyle(color: Colors.green),
                        )
                      : const Text('Offline'),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () => _showUnfriendDialog(friend),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendRequests() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Please login'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No friend requests', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            FriendRequestModel request = FriendRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(request.senderId)
                  .get(),
              builder: (context, senderSnapshot) {
                if (senderSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text('Loading...'));
                }

                if (!senderSnapshot.hasData || !senderSnapshot.data!.exists) {
                  return const ListTile(title: Text('Unknown User'));
                }

                UserModel sender = UserModel.fromMap(
                  senderSnapshot.data!.data() as Map<String, dynamic>,
                );

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(sender.name[0].toUpperCase()),
                  ),
                  title: Text(sender.name),
                  subtitle: Text('Sent ${_formatDate(request.createdAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _acceptFriendRequest(request.id, request.senderId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectFriendRequest(request.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFindFriends() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search friends',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  : null,
            ),
            onChanged: _searchUsers,
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? const Center(child: Text('Search for friends by name'))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    UserModel user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name[0].toUpperCase()),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: ElevatedButton(
                        onPressed: () => _sendFriendRequest(user),
                        child: const Text('Add Friend'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showUnfriendDialog(UserModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${friend.name}?'),
        content: Text(
          'Are you sure you want to remove ${friend.name} from your friends list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unfriendUser(friend.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
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
