import 'package:flutter/material.dart';

class ChallengeWidget extends StatelessWidget {
  final List<Map<String, dynamic>> challenges = [
    {'title': '7 Günde 5 Tarama', 'points': 100, 'progress': 0.4},
    {'title': 'Her gün 10 bin adım', 'points': 50, 'progress': 0.7},
    {'title': 'Diyeti 3 gün uygula', 'points': 75, 'progress': 0.0},
    {'title': 'Günde 2 litre su', 'points': 30, 'progress': 0.6},
  ];

  ChallengeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Günlük Meydan Okumalar')),
      body: ListView.builder(
        itemCount: challenges.length,
        itemBuilder: (ctx, idx) {
          final c = challenges[idx];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber,
                child: Text('${c['points']}', style: TextStyle(color: Colors.black)),
              ),
              title: Text(c['title']),
              subtitle: LinearProgressIndicator(
                value: c['progress'],
                backgroundColor: Colors.grey[300],
                color: Colors.green,
              ),
              trailing: Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
