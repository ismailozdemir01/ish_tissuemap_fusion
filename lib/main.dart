import 'package:flutter/material.dart';
import 'package:ish_tissuemap_fusion/screens/connection_screen.dart';
import 'package:ish_tissuemap_fusion/core/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISH TissueMap Fusion',
      theme: AppTheme.darkTheme,
      home: const ConnectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
