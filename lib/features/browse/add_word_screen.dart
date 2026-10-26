import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../providers.dart';

final _hangul = RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]');

/// Adds a word of your own, or edits one when [existing] is given.
class AddWordScreen extends ConsumerStatefulWidget {
  const AddWordScreen({super.key, this.existing});
  final Word? existing;

  @override
  ConsumerState<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends ConsumerState<AddWordScreen> {
  final _form = GlobalKey<FormState>();
  late final _word = TextEditingController(text: widget.existing?.word);
  late final _meaning = TextEditingController(text: widget.existing?.senseList.firstOrNull?.meanings.join(', '));
  late final _example = TextEditingController(text: widget.existing?.senseList.firstOrNull?.example);
  late final _note = TextEditingController(text: widget.existing?.note);
  late String _pos = _posOptions.contains(widget.existing?.pos) ? widget.existing!.pos : 'noun';
  late String _unit = widget.existing?.unitId ?? customUnit;

  static const _posOptions = ['noun', 'verb', 'adjective', 'adverb', 'expression', 'other'];

  @override
  void dispose() {
    for (final c in [_word, _meaning, _example, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final db = ref.read(dbProvider);
    final meanings = _meaning.text.split(RegExp(r'[,;]')).map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    final word = _word.text.trim();
    final existing = widget.existing;
    if (existing != null) {
      await db.updateCustomWord(existing.id,
          word: word, pos: _pos, meanings: meanings, example: optional(_example), note: optional(_note), unit: _unit);
    } else {
      await db.addCustomWord(word: word, pos: _pos, meanings: meanings, example: optional(_example), note: optional(_note), unit: _unit);
      final game = ref.read(gameProvider);
      await game.award([game.activity(ActivityKind.wordAdded)]);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(existing != null ? 'Saved $word' : 'Added $word ✏️ — find it in Learn → Topics and in your flashcards'),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(curriculumProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add a word' : 'Edit word')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _word,
              autofocus: widget.existing == null,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(labelText: 'Korean', hintText: '예: 맛있다', border: OutlineInputBorder()),
              validator: (v) => v == null || !_hangul.hasMatch(v) ? 'Enter the word in Hangul' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _meaning,
              decoration: const InputDecoration(
                labelText: 'English meaning',
                hintText: 'delicious, tasty',
                helperText: 'Separate meanings with commas',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter at least one meaning' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _pos,
                  decoration: const InputDecoration(labelText: 'Part of speech', border: OutlineInputBorder()),
                  items: [for (final p in _posOptions) DropdownMenuItem(value: p, child: Text(p))],
                  onChanged: (v) => setState(() => _pos = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: units.any((u) => u.id == _unit) ? _unit : customUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
                  items: [
                    for (final u in units) DropdownMenuItem(value: u.id, child: Text('${u.emoji} ${u.title}', overflow: TextOverflow.ellipsis)),
                    if (units.isEmpty) const DropdownMenuItem(value: customUnit, child: Text('✏️ My words')),
                  ],
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _example,
              decoration: const InputDecoration(labelText: 'Example sentence (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
