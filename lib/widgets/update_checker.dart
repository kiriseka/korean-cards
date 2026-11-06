import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/update_dialog.dart';
import '../providers.dart';
import '../services/update_service.dart';
import '../settings.dart';
import 'celebrations.dart';

/// Looks for a new version on GitHub shortly after launch (at most once a day, if switched on in
/// Settings) and offers it. Fails silently: the app is meant to work offline.
class UpdateChecker extends ConsumerStatefulWidget {
  const UpdateChecker({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLaunch());
  }

  Future<void> _onLaunch() async {
    final service = ref.read(updateServiceProvider);
    final store = ref.read(updateStoreProvider);
    final app = await service.appInfo();
    if (app == null || !mounted) return; // tests, non-Android

    // Android can restart the app after "Install unknown apps" is switched on: offer the
    // download that was waiting.
    final pending = store.pending(DateTime.now());
    if (pending != null && pending.version > app.version && File(pending.path).existsSync()) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        await showPendingInstallDialog(context, service, store, File(pending.path), pending.version);
      }
      return;
    }
    await store.clearPending();
    await service.cleanUp();

    if (!ref.read(settingsProvider).autoUpdateCheck || !store.dueForCheck(DateTime.now())) return;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final UpdateOffer? offer;
    try {
      offer = await service.check(app);
      await store.markChecked(DateTime.now());
    } on UpdateException {
      return;
    }
    if (offer == null || store.isSkipped(offer.version)) return;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showUpdateDialog(context, service, store, offer, fromAutoCheck: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
