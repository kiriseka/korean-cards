import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/update_service.dart';
import '../../widgets/celebrations.dart';

/// "Update available" → download with progress → Android's installer.
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateService service,
  UpdateStore store,
  UpdateOffer offer, {
  bool fromAutoCheck = false,
}) async {
  final choice = await showDialog<_Choice>(
    context: context,
    builder: (context) => _OfferDialog(offer: offer, canSkip: fromAutoCheck),
  );
  switch (choice) {
    case _Choice.skip:
      await store.skip(offer.version);
    case _Choice.update:
      final dialogContext = navigatorKey.currentContext;
      if (dialogContext == null || !dialogContext.mounted) return;
      final result = await showDialog<Object>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (_) => _DownloadDialog(service: service, apk: offer.apk),
      );
      if (result is File) {
        await store.setPending(result.path, offer.version, DateTime.now());
        await installUpdate(service, result);
      } else if (result is UpdateException) {
        _snack(result.message);
      }
    case _Choice.later || null:
      break;
  }
}

/// A download that finished just before Android restarted the app.
Future<void> showPendingInstallDialog(BuildContext context, UpdateService service, UpdateStore store, File apk, Version version) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('새 버전 · Ready to install'),
      content: Text('Version $version is downloaded. Install it now? Your progress is kept.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Install')),
      ],
    ),
  );
  if (ok == true) {
    await installUpdate(service, apk);
  } else {
    await store.clearPending();
    await service.cleanUp();
  }
}

/// Opens Android's installer, first asking for "Install unknown apps" if needed.
Future<void> installUpdate(UpdateService service, File apk) async {
  try {
    if (await service.install(apk) == InstallResult.started) return;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow updates'),
        content: const Text(
          'Android needs your OK once to let Korean Cards install its own updates.\n\n'
          'Turn on "Allow from this source", then come back here.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Open settings')),
        ],
      ),
    );
    if (go != true) return;
    final back = _nextResume();
    await service.openInstallSettings();
    await back;
    if (await service.install(apk) == InstallResult.needsPermission) {
      _snack('Installing updates is still off. Try again from Settings → Check for updates.');
    }
  } on Exception catch (e) {
    _snack("Couldn't open the installer: $e");
  }
}

Future<void> _nextResume() {
  final done = Completer<void>();
  late final AppLifecycleListener listener;
  listener = AppLifecycleListener(onResume: () {
    listener.dispose();
    if (!done.isCompleted) done.complete();
  });
  return done.future;
}

void _snack(String text) =>
    messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Release notes as plain text: no markdown markers, and without the "Which APK" paragraph
/// (the app picks the APK itself).
String plainNotes(String markdown) => markdown
    .split(RegExp(r'\n\s*\n'))
    .where((p) => !p.trimLeft().startsWith('Which APK'))
    .join('\n\n')
    .replaceAll(RegExp(r'\*\*|__|`'), '')
    .replaceAllMapped(RegExp(r'^\s*#+\s*', multiLine: true), (_) => '')
    .replaceAllMapped(RegExp(r'^(\s*)[-*] ', multiLine: true), (m) => '${m[1]}• ')
    .trim();

enum _Choice { update, later, skip }

class _OfferDialog extends StatelessWidget {
  const _OfferDialog({required this.offer, required this.canSkip});
  final UpdateOffer offer;
  final bool canSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = plainNotes(offer.release.notes);
    return AlertDialog(
      title: const Text('새 버전 · Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${offer.version} is ready (you have ${offer.current}). '
              'It is a ${_mb(offer.apk.size)} download and keeps your progress.'),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(child: Text(notes, style: theme.textTheme.bodySmall)),
            ),
          ],
        ],
      ),
      actions: [
        if (canSkip) TextButton(onPressed: () => Navigator.pop(context, _Choice.skip), child: const Text('Skip this version')),
        TextButton(onPressed: () => Navigator.pop(context, _Choice.later), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, _Choice.update), child: const Text('Update')),
      ],
    );
  }
}

/// Pops with the verified [File], an [UpdateException], or null when cancelled.
class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.service, required this.apk});
  final UpdateService service;
  final ReleaseAsset apk;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  final _cancel = CancelToken();
  int _received = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _total = widget.apk.size;
    _run();
  }

  Future<void> _run() async {
    Object? result;
    try {
      result = await widget.service.download(
        widget.apk,
        cancel: _cancel,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _received = received;
              _total = total;
            });
          }
        },
      );
    } on UpdateCancelled {
      result = null;
    } on UpdateException catch (e) {
      result = e;
    }
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _received / _total : null;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Downloading update'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Text(_total > 0 ? '${_mb(_received)} / ${_mb(_total)}' : _mb(_received)),
        ]),
        actions: [
          TextButton(
            onPressed: _cancel.cancelled ? null : () => setState(_cancel.cancel),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
