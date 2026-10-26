import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../dictionary/dictionary_service.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Loads the dictionary on first use, showing progress; then shows [child].
class DictionaryGate extends ConsumerStatefulWidget {
  const DictionaryGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<DictionaryGate> createState() => _DictionaryGateState();
}

class _DictionaryGateState extends ConsumerState<DictionaryGate> {
  double? _progress;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dict = ref.read(dictionaryProvider);
    if (await dict.ready) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    if (mounted) setState(() => _progress = 0);
    await dict.ensureLoaded(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p.clamp(0, 1));
      },
    );
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Setting up the dictionary (53,000 words)…\nOnly the first time.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
        ),
      ),
    );
  }
}

/// Runs [action] once after first build (e.g. the first search once the dictionary is ready).
class RunOnce extends StatefulWidget {
  const RunOnce({super.key, required this.action, required this.child});
  final VoidCallback action;
  final Widget child;

  @override
  State<RunOnce> createState() => _RunOnceState();
}

class _RunOnceState extends State<RunOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.action());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One dictionary result: word, level, meaning; tap for details and "Add to my words".
class DictEntryTile extends ConsumerWidget {
  const DictEntryTile({super.key, required this.entry});
  final DictEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inDeck = ref.watch(allWordsProvider).value?.any((w) => w.id == entry.id) ?? false;
    return ListTile(
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: entry.word,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (entry.hanja != null)
              TextSpan(
                text: '  ${entry.hanja}',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
          ],
        ),
      ),
      subtitle: Text(
        '${entry.pos}${entry.level.isEmpty ? '' : ' · ${entry.level}'} — ${entry.gloss}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: inDeck ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.add_circle_outline),
      onTap: () => showEntrySheet(context, ref, entry),
    );
  }
}

Future<void> showEntrySheet(BuildContext context, WidgetRef ref, DictEntry e) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => Consumer(
    builder: (context, ref, _) {
      final theme = Theme.of(context);
      final inDeck = ref.watch(allWordsProvider).value?.any((w) => w.id == e.id) ?? false;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(e.word, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                SpeakButton(e.word),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                TagChip(e.pos),
                if (e.level.isNotEmpty) TagChip(e.level),
                if (e.pronunciation != null) Text('[${e.pronunciation}]'),
                if (e.hanja != null) Text(e.hanja!),
              ],
            ),
            const SizedBox(height: 12),
            for (final (i, s) in e.senseList.indexed) ...[
              Text(
                '${i + 1}. ${s.meanings.join(', ')}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (s.definition.isNotEmpty) Text(s.definition),
              const SizedBox(height: 6),
            ],
            if (e.example != null)
              Row(
                children: [
                  Expanded(
                    child: Text(e.example!, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  SpeakButton(e.example!, size: 22),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: inDeck
                  ? const OutlinedButton(onPressed: null, child: Text('✓ In your words'))
                  : FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add to my words'),
                      onPressed: () async {
                        await ref.read(dictionaryProvider).addToDeck(e);
                        final game = ref.read(gameProvider);
                        await game.award([game.activity(ActivityKind.wordAdded)]);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Added ${e.word} to My words ✏️')));
                        }
                      },
                    ),
            ),
          ],
        ),
      );
    },
  ),
);

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<DictEntry>? _results;
  int _token = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final t = ++_token;
      final r = await ref.read(dictionaryProvider).search(q);
      if (mounted && t == _token) setState(() => _results = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📖 Dictionary')),
      body: DictionaryGate(
        child: RunOnce(
          action: () {
            if (widget.initialQuery.isNotEmpty) _search(widget.initialQuery);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _controller,
                  hintText: 'Korean or English (먹었어요, apple…)',
                  leading: const Icon(Icons.search),
                  onChanged: _search,
                ),
              ),
              Expanded(
                child: _results == null
                    ? const Center(
                        child: Text(
                          'Search any of 53,000 words.\nConjugated forms work too: 갔어요 → 가다',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _results!.isEmpty
                    ? const Center(child: Text('No matches'))
                    : ListView.builder(
                        itemCount: _results!.length,
                        itemBuilder: (_, i) => DictEntryTile(entry: _results![i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
