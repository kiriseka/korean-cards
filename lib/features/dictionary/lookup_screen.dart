import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../dictionary/lemmatizer.dart';
import '../../providers.dart';
import 'dictionary_screen.dart';

/// Text shared from another app (or selected → Korean Cards): every word, looked up.
class LookupScreen extends ConsumerStatefulWidget {
  const LookupScreen({super.key, required this.text});
  final String text;

  @override
  ConsumerState<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends ConsumerState<LookupScreen> {
  List<(String token, List<DictEntry> matches)>? _rows;

  Future<void> _lookup() async {
    final dict = ref.read(dictionaryProvider);
    final seen = <String>{};
    final rows = <(String, List<DictEntry>)>[];
    for (final t in tokenize(widget.text)) {
      if (!seen.add(t)) continue;
      // Up to 4 matches, at most 2 per spelling, so 듣다 isn't crowded out by four 들다s.
      final perWord = <String, int>{};
      final matches = (await dict.lookup(t)).where((e) => (perWord[e.word] = (perWord[e.word] ?? 0) + 1) <= 2).take(4).toList();
      rows.add((t, matches));
      if (rows.length >= 60) break;
    }
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _addAllNew() async {
    final dict = ref.read(dictionaryProvider);
    var added = 0;
    for (final (_, m) in _rows ?? const <(String, List<DictEntry>)>[]) {
      if (m.isNotEmpty && await dict.addToDeck(m.first)) added++;
    }
    if (added > 0) {
      final game = ref.read(gameProvider);
      await game.award([for (var i = 0; i < added; i++) game.activity(ActivityKind.wordAdded)]);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added == 0 ? 'All of these are already in your words' : 'Added $added words to My words ✏️'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Look up'),
        actions: [
          if (_rows != null && _rows!.isNotEmpty) TextButton(onPressed: _addAllNew, child: const Text('Add all')),
        ],
      ),
      body: DictionaryGate(
        child: RunOnce(
          action: _lookup,
          child: _rows == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card.filled(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            widget.text,
                            style: theme.textTheme.bodyLarge,
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (_rows!.isEmpty) const Center(child: Text('No Korean words found in that text.')),
                    for (final (token, matches) in _rows!) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          token,
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                      if (matches.isEmpty)
                        const ListTile(dense: true, title: Text('Not found (a name, slang or a rare form)'))
                      else
                        for (final m in matches) DictEntryTile(entry: m),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
