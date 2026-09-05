import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/models/community_post.dart';
import 'package:ish_tissuemap_fusion/screens/community/challenge_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityPost> _posts = [];
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDummyPosts();
  }

  void _loadDummyPosts() {
    _posts = [
      CommunityPost(
        id: '1',
        username: 'Ali Sağlıkçı',
        profileImage: '👨‍⚕️',
        content: 'Bugün karaciğer taramam %15 iyileşme gösterdi! 🌟',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        likes: 12,
        comments: 3,
      ),
      CommunityPost(
        id: '2',
        username: 'Zeynep Hoca',
        profileImage: '🧘‍♀️',
        content: 'ISH ile 3 aydır takip ediyorum, diyet işe yarıyor!',
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        likes: 8,
        comments: 2,
      ),
      CommunityPost(
        id: '3',
        username: 'Mehmet Bey',
        profileImage: '🏃',
        content: 'Her gün 10 bin adım, skorlar düşüyor 💪',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        likes: 5,
        comments: 1,
      ),
    ];
  }

  void _addPost(String content) {
    if (content.trim().isEmpty) return;
    setState(() {
      _posts.insert(0, CommunityPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: 'Ben',
        profileImage: '🧑',
        content: content,
        timestamp: DateTime.now(),
        likes: 0,
        comments: 0,
      ));
    });
    _postController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Paylaşım eklendi!'),
      backgroundColor: Colors.green,
    ));
  }

  void _toggleLike(String id) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _posts[index].likes += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ISH Topluluğu'),
        actions: [
          IconButton(icon: Icon(Icons.emoji_events), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChallengeWidget()),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Yeni paylaşım alanı
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: InputDecoration(
                      hintText: 'Sağlık hikayeni paylaş...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      fillColor: Colors.grey[800],
                      filled: true,
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _addPost(_postController.text),
                ),
              ],
            ),
          ),
          // Paylaşımlar listesi
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (ctx, idx) {
                final post = _posts[idx];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(post.profileImage, style: TextStyle(fontSize: 32)),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.username, style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  _timeAgo(post.timestamp),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(post.content, style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.favorite_border, color: Colors.red),
                              onPressed: () => _toggleLike(post.id),
                            ),
                            Text('${post.likes}'),
                            SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.comment, color: Colors.grey),
                              onPressed: () {},
                            ),
                            Text('${post.comments}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'Şimdi';
  }
}
