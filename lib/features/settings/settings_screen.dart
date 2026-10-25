import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';
import '../../services/backup_service.dart';
import '../../settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('설정 · Settings')),
      body: ListView(
        children: [
          header('Study'),
          ListTile(
            title: const Text('New words per day'),
            subtitle: Slider(
              value: s.newPerDay.toDouble(),
              min: 0,
              max: 50,
              divisions: 10,
              label: '${s.newPerDay}',
              onChanged: (v) => notifier.update((s) => s.copyWith(newPerDay: v.round())),
            ),
            trailing: Text('${s.newPerDay}', style: theme.textTheme.titleMedium),
          ),
          ListTile(
            title: const Text('Maximum reviews per day'),
            trailing: DropdownButton<int>(
              value: s.reviewCap,
              items: [for (final v in [50, 100, 200, 500, 9999]) DropdownMenuItem(value: v, child: Text(v == 9999 ? 'No limit' : '$v'))],
              onChanged: (v) => notifier.update((s) => s.copyWith(reviewCap: v)),
            ),
          ),
          SwitchListTile(
            title: const Text('Also practise English → Korean'),
            subtitle: const Text('Adds a reverse card once you have studied a word'),
            value: s.reverseCards,
            onChanged: (v) => notifier.update((s) => s.copyWith(reverseCards: v)),
          ),
          header('Audio'),
          SwitchListTile(
            title: const Text('Play pronunciation automatically'),
            value: s.autoPlay,
            onChanged: (v) => notifier.update((s) => s.copyWith(autoPlay: v)),
          ),
          ListTile(
            title: const Text('Speech speed'),
            subtitle: Slider(
              value: s.speechRate,
              min: 0.2,
              max: 0.8,
              divisions: 6,
              onChanged: (v) => notifier.update((s) => s.copyWith(speechRate: v)),
            ),
            trailing: IconButton(
              tooltip: 'Test',
              icon: const Icon(Icons.volume_up),
              onPressed: () => ref.speak('안녕하세요. 만나서 반가워요.'),
            ),
          ),
          header('Reminder'),
          SwitchListTile(
            title: const Text('Daily reminder'),
            value: s.reminderEnabled,
            onChanged: (on) => _setReminder(context, ref, on, s.reminderTime),
          ),
          ListTile(
            enabled: s.reminderEnabled,
            title: const Text('Reminder time'),
            trailing: Text(s.reminderTime.format(context), style: theme.textTheme.titleMedium),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: s.reminderTime);
              if (t != null && context.mounted) await _setReminder(context, ref, true, t);
            },
          ),
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => notifier.update((s) => s.copyWith(themeMode: v.first)),
            ),
          ),
          header('Backup'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export progress'),
            subtitle: const Text('Save a backup file you can restore later'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Import progress'),
            subtitle: const Text('Replace current progress with a backup file'),
            onTap: () => _import(context, ref),
          ),
          header('About'),
          const ListTile(
            title: Text('Word data'),
            subtitle: Text(
              'Words, meanings and examples: 한국어기초사전 (Basic Korean Dictionary), '
              'National Institute of Korean Language — CC BY-SA 2.0 KR.\n'
              'Learning order from subtitle word frequencies (hermitdave/FrequencyWords, CC BY-SA 4.0).\n'
              'Scheduling: FSRS (open-spaced-repetition).',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _setReminder(BuildContext context, WidgetRef ref, bool on, TimeOfDay time) async {
    final notifications = ref.read(notificationsProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (on && !await notifications.requestPermission()) {
      messenger.showSnackBar(const SnackBar(content: Text('Notifications are blocked. Allow them in Android settings.')));
      return;
    }
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(reminderEnabled: on, reminderTime: time));
    if (on) {
      await notifications.scheduleDaily(time);
    } else {
      await notifications.cancelDaily();
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final json = await BackupService(ref.read(dbProvider)).export();
    final uri = await FilePicker.saveFile(
      fileName: 'korean-cards-${DateFormat('yyyyMMdd').format(DateTime.now())}.json',
      bytes: utf8.encode(json),
      mimeType: 'application/json',
    );
    if (uri != null) messenger.showSnackBar(const SnackBar(content: Text('Backup saved')));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await FilePicker.pickFile();
    if (file == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace progress?'),
        content: Text('All current progress will be replaced with ${file.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await BackupService(ref.read(dbProvider)).import(await file.xFile.readAsString());
      messenger.showSnackBar(const SnackBar(content: Text('Progress restored')));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not import: ${e.message}')));
    }
  }
}
