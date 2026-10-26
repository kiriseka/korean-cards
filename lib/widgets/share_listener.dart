import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/dictionary/lookup_screen.dart';
import 'celebrations.dart';

/// Opens the look-up screen for text shared from other apps or picked from the selection menu
/// (see MainActivity.kt) — both at launch and while the app is running.
class ShareListener extends StatefulWidget {
  const ShareListener({super.key, required this.child});
  final Widget child;

  static const channel = MethodChannel('korean_cards/share');

  @override
  State<ShareListener> createState() => _ShareListenerState();
}

class _ShareListenerState extends State<ShareListener> {
  @override
  void initState() {
    super.initState();
    ShareListener.channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText') _open(call.arguments as String);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final text = await ShareListener.channel.invokeMethod<String>('initialText');
        if (text != null) _open(text);
      } on MissingPluginException {
        // Tests and non-Android platforms have no share channel.
      }
    });
  }

  void _open(String text) =>
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => LookupScreen(text: text)));

  @override
  Widget build(BuildContext context) => widget.child;
}
