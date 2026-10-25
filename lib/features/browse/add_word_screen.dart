import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

final _hangul = RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]');

class AddWordScreen extends ConsumerStatefulWidget {
  const AddWordScreen({super.key});

  @override
  ConsumerState<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends ConsumerState<AddWordScreen> {
  final _form = GlobalKey<FormState>();
  final _word = TextEditingController();
  final _meaning = TextEditingController();
  final _example = TextEditingController();
  final _note = TextEditingController();
  String _pos = 'noun';

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
    await ref.read(dbProvider).addCustomWord(
          word: _word.text.trim(),
          pos: _pos,
          meanings: _meaning.text.split(RegExp(r'[,;]')).map((m) => m.trim()).where((m) => m.isNotEmpty).toList(),
          example: optional(_example),
          note: optional(_note),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${_word.text.trim()} — it will be your next new card')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a word')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _word,
              autofocus: true,
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
            DropdownButtonFormField<String>(
              initialValue: _pos,
              decoration: const InputDecoration(labelText: 'Part of speech', border: OutlineInputBorder()),
              items: [for (final p in _posOptions) DropdownMenuItem(value: p, child: Text(p))],
              onChanged: (v) => setState(() => _pos = v!),
            ),
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
