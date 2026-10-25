import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import 'add_word_screen.dart';
import 'word_detail_screen.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _query = '';
  WordFilter _filter = WordFilter.all;
  late Stream<List<CardWithWord>> _words = _watch();

  Stream<List<CardWithWord>> _watch() => ref.read(dbProvider).watchWords(query: _query, filter: _filter);

  void _update({String? query, WordFilter? filter}) => setState(() {
        _query = query ?? _query;
        _filter = filter ?? _filter;
        _words = _watch();
      });

  static const _filterLabels = {
    WordFilter.all: 'All',
    WordFilter.newWords: 'New',
    WordFilter.learning: 'Learning',
    WordFilter.known: 'Known',
    WordFilter.starred: '★ Starred',
    WordFilter.suspended: 'Suspended',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('단어 · Words')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add word'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWordScreen())),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search Korean or English',
              leading: const Icon(Icons.search),
              onChanged: (q) => _update(query: q),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in WordFilter.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(_filterLabels[f]!),
                      selected: _filter == f,
                      onSelected: (_) => _update(filter: f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _words,
              builder: (context, snap) {
                final items = snap.data;
                if (items == null) return const Center(child: CircularProgressIndicator());
                if (items.isEmpty) return const Center(child: Text('No words found'));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Text('${items.length} words', style: Theme.of(context).textTheme.labelMedium),
                      );
                    }
                    return _WordTile(item: items[i - 1]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.item});
  final CardWithWord item;

  @override
  Widget build(BuildContext context) {
    final w = item.word;
    return ListTile(
      leading: StatusDot(CardStatus.of(item.card)),
      title: Text.rich(TextSpan(children: [
        TextSpan(text: w.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        if (w.hanja != null)
          TextSpan(text: '  ${w.hanja}', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      ])),
      subtitle: Text(w.gloss, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: w.starred ? const Icon(Icons.star, color: Colors.amber) : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WordDetailScreen(wordId: w.id))),
    );
  }
}
