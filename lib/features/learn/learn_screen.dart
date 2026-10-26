import 'package:flutter/material.dart';

import '../talk/talk_view.dart';
import 'grammar_view.dart';
import 'topics_view.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('배우기 · Learn'),
            bottom: const TabBar(tabs: [Tab(text: '🗂️ Topics'), Tab(text: '🗣️ Talk'), Tab(text: '📐 Grammar')]),
          ),
          body: const TabBarView(children: [TopicsView(), TalkView(), GrammarView()]),
        ),
      );
}
