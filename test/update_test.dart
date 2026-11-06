import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:korean_cards/features/settings/update_dialog.dart';
import 'package:korean_cards/services/update_service.dart';
import 'package:korean_cards/settings.dart';
import 'package:korean_cards/widgets/celebrations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> asset(String name, {int size = 100, String? digest}) => {
      'name': name,
      'size': size,
      'digest': digest,
      'browser_download_url': 'https://github.com/kiriseka/korean-cards/releases/download/x/$name',
    };

Map<String, dynamic> release(String tag, String version, {bool draft = false, bool prerelease = false, List<String>? variants}) => {
      'tag_name': tag,
      'name': 'V$version',
      'draft': draft,
      'prerelease': prerelease,
      'body': 'New in $version',
      'html_url': 'https://github.com/kiriseka/korean-cards/releases/tag/$tag',
      'assets': [for (final v in variants ?? ['arm64', 'armv7', 'universal']) asset('korean-cards-$version-$v.apk')],
    };

/// Same shape as the real list: messy tags, newest first.
final realLike = [
  release('V1.4.0', '1.4.0'),
  release('Stable', '1.2.0'),
  release('Latest', '1.3.0'),
];

const arm64Split = AppInfo(versionName: '1.4.0', versionCode: 2005, abis: ['arm64-v8a', 'armeabi-v7a', 'armeabi']);

void main() {
  group('Version', () {
    test('parses with or without V and build number', () {
      expect(Version.tryParse('1.4.0'), const Version(1, 4, 0));
      expect(Version.tryParse('V1.4.0'), const Version(1, 4, 0));
      expect(Version.tryParse('v2.10.3+7'), const Version(2, 10, 3));
      expect(Version.tryParse('Latest'), isNull);
      expect(Version.tryParse('1.4'), isNull);
      expect(Version.tryParse(null), isNull);
    });

    test('orders numerically', () {
      expect(const Version(1, 10, 0) > const Version(1, 9, 9), isTrue);
      expect(const Version(2, 0, 0) > const Version(1, 99, 99), isTrue);
      expect(const Version(1, 4, 1) > const Version(1, 4, 0), isTrue);
      expect(const Version(1, 4, 0) <= const Version(1, 4, 0), isTrue);
      expect(const Version(1, 4, 0) > const Version(1, 4, 0), isFalse);
    });
  });

  group('latestRelease', () {
    test('reads the version from APK names, not tags', () {
      final r = latestRelease(realLike)!;
      expect(r.version, const Version(1, 4, 0));
      expect(r.assets.map((a) => a.variant), containsAll(ApkVariant.values));
      expect(r.notes, 'New in 1.4.0');
    });

    test('skips drafts, prereleases and releases without APKs', () {
      final r = latestRelease([
        release('V2.0.0', '2.0.0', draft: true),
        release('V1.9.0', '1.9.0', prerelease: true),
        {...release('V1.8.0', '1.8.0'), 'assets': [asset('notes.txt')]},
        ...realLike,
      ])!;
      expect(r.version, const Version(1, 4, 0));
    });

    test('reads the sha256 digest', () {
      final a = ReleaseAsset.fromJson(asset('korean-cards-1.4.0-arm64.apk', digest: 'sha256:ABC123'))!;
      expect(a.sha256, 'abc123');
      expect(ReleaseAsset.fromJson(asset('korean-cards-1.4.0-arm64.apk'))!.sha256, isNull);
      expect(ReleaseAsset.fromJson(asset('korean-cards-1.4.0-x86.apk')), isNull);
    });

    test('nothing usable gives null', () {
      expect(latestRelease([]), isNull);
      expect(latestRelease([release('V1.0.0', '1.0.0', draft: true)]), isNull);
    });
  });

  group('pickAsset', () {
    final all = latestRelease([release('V1.5.0', '1.5.0')])!;
    final universalOnly = latestRelease([release('V1.5.0', '1.5.0', variants: ['universal'])])!;
    ApkVariant? pick(AvailableUpdate u, int code, String abi) =>
        pickAsset(u, AppInfo(versionName: '1.4.0', versionCode: code, abis: [abi]))?.variant;

    test('split installs get their own ABI', () {
      expect(pick(all, 2005, 'arm64-v8a'), ApkVariant.arm64);
      expect(pick(all, 1005, 'armeabi-v7a'), ApkVariant.armv7);
    });

    test('universal installs prefer the ABI APK, else universal', () {
      expect(pick(all, 5, 'arm64-v8a'), ApkVariant.arm64);
      expect(pick(universalOnly, 5, 'arm64-v8a'), ApkVariant.universal);
      expect(pick(all, 5, 'x86_64'), ApkVariant.universal);
    });

    test('split installs never get universal (it would be a downgrade)', () {
      expect(pick(universalOnly, 2005, 'arm64-v8a'), isNull);
      expect(pick(all, 4005, 'x86_64'), isNull);
    });
  });

  group('check', () {
    UpdateService serviceFor(http.Response Function(http.Request) handler) =>
        UpdateService(MockClient((req) async => handler(req)));

    test('offers a newer version with the right APK', () async {
      late http.Request seen;
      final service = serviceFor((req) {
        seen = req;
        return http.Response(jsonEncode([release('V1.5.0', '1.5.0'), ...realLike]), 200);
      });
      final offer = (await service.check(arm64Split))!;
      expect(offer.version, const Version(1, 5, 0));
      expect(offer.current, const Version(1, 4, 0));
      expect(offer.apk.name, 'korean-cards-1.5.0-arm64.apk');
      expect(seen.url.toString(), releasesUrl);
      expect(seen.headers['User-Agent'], isNotEmpty);
    });

    test('same or older version is up to date', () async {
      final service = serviceFor((_) => http.Response(jsonEncode(realLike), 200));
      expect(await service.check(arm64Split), isNull);
      expect(await service.check(const AppInfo(versionName: '1.5.0', versionCode: 2006, abis: ['arm64-v8a'])), isNull);
    });

    test('rate limits and bad responses throw UpdateException', () async {
      await expectLater(serviceFor((_) => http.Response('{}', 403)).check(arm64Split), throwsA(isA<UpdateException>()));
      await expectLater(serviceFor((_) => http.Response('oops', 500)).check(arm64Split), throwsA(isA<UpdateException>()));
      await expectLater(serviceFor((_) => http.Response('not json', 200)).check(arm64Split), throwsA(isA<UpdateException>()));
    });

    test('network errors throw UpdateException', () async {
      final service = UpdateService(MockClient((_) async => throw const SocketException('offline')));
      await expectLater(service.check(arm64Split), throwsA(isA<UpdateException>()));
    });

    test('newer version without an APK for this phone throws', () async {
      final service = serviceFor((_) => http.Response(jsonEncode([release('V1.5.0', '1.5.0', variants: ['universal'])]), 200));
      await expectLater(service.check(arm64Split), throwsA(isA<UpdateException>()));
    });
  });

  group('download', () {
    late Directory dir;
    final bytes = List<int>.generate(5000, (i) => i % 251);
    final good = sha256.convert(bytes).toString();

    setUp(() => dir = Directory.systemTemp.createTempSync('kc_update_'));
    tearDown(() => dir.deleteSync(recursive: true));

    ReleaseAsset apk({int? size, String? digest}) => ReleaseAsset.fromJson(
        asset('korean-cards-1.5.0-arm64.apk', size: size ?? bytes.length, digest: 'sha256:${digest ?? good}'))!;
    UpdateService service() =>
        UpdateService(MockClient((_) async => http.Response.bytes(bytes, 200)), downloadDir: Directory('${dir.path}/updates'));

    test('saves a verified file and reports progress', () async {
      final progress = <int>[];
      final file = await service().download(apk(), onProgress: (r, t) {
        expect(t, bytes.length);
        progress.add(r);
      });
      expect(file.readAsBytesSync(), bytes);
      expect(file.path, endsWith('korean-cards-1.5.0-arm64.apk'));
      expect(progress.last, bytes.length);
    });

    test('a wrong digest or size is rejected and deleted', () async {
      await expectLater(service().download(apk(digest: '0' * 64)), throwsA(isA<UpdateException>()));
      await expectLater(service().download(apk(size: 9999)), throwsA(isA<UpdateException>()));
      expect(Directory('${dir.path}/updates').listSync(), isEmpty);
    });

    test('cancelling stops and deletes', () async {
      await expectLater(service().download(apk(), cancel: CancelToken()..cancel()), throwsA(isA<UpdateCancelled>()));
      expect(Directory('${dir.path}/updates').listSync(), isEmpty);
    });

    test('HTTP errors throw UpdateException', () async {
      final s = UpdateService(MockClient((_) async => http.Response('gone', 404)), downloadDir: Directory('${dir.path}/updates'));
      await expectLater(s.download(apk()), throwsA(isA<UpdateException>()));
    });

    test('cleanUp removes downloads', () async {
      final s = service();
      await s.download(apk());
      await s.cleanUp();
      expect(Directory('${dir.path}/updates').existsSync(), isFalse);
    });
  });

  group('UpdateStore', () {
    late UpdateStore store;
    final now = DateTime(2026, 11, 6, 12);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = UpdateStore(await SharedPreferences.getInstance());
    });

    test('checks once a day', () async {
      expect(store.dueForCheck(now), isTrue);
      await store.markChecked(now);
      expect(store.dueForCheck(now.add(const Duration(hours: 23))), isFalse);
      expect(store.dueForCheck(now.add(const Duration(hours: 24))), isTrue);
    });

    test('skipped versions stay skipped, newer ones are offered', () async {
      expect(store.isSkipped(const Version(1, 5, 0)), isFalse);
      await store.skip(const Version(1, 5, 0));
      expect(store.isSkipped(const Version(1, 5, 0)), isTrue);
      expect(store.isSkipped(const Version(1, 5, 1)), isFalse);
    });

    test('a pending download expires after an hour', () async {
      await store.setPending('/cache/updates/a.apk', const Version(1, 5, 0), now);
      expect(store.pending(now.add(const Duration(minutes: 10)))?.version, const Version(1, 5, 0));
      expect(store.pending(now.add(const Duration(hours: 2))), isNull);
      await store.clearPending();
      expect(store.pending(now), isNull);
    });
  });

  test('autoUpdateCheck setting round-trips', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(Settings.load(prefs).autoUpdateCheck, isTrue);
    await const Settings().copyWith(autoUpdateCheck: false).save(prefs);
    expect(Settings.load(prefs).autoUpdateCheck, isFalse);
  });

  test('release notes become plain text without the APK guide', () {
    const md = 'New in 1.5:\n\n- 🔄 **Updates**: the app updates itself.\n- `code`\n\n'
        'Which APK: **arm64** fits almost every modern phone.\n';
    expect(plainNotes(md), 'New in 1.5:\n\n• 🔄 Updates: the app updates itself.\n• code');
  });

  testWidgets('update dialog shows the offer and remembers Skip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = UpdateStore(await SharedPreferences.getInstance());
    final service = UpdateService(MockClient((_) async => http.Response('', 404)));
    final update = latestRelease([release('V1.5.0', '1.5.0')])!;
    final offer = UpdateOffer(current: const Version(1, 4, 0), release: update, apk: pickAsset(update, arm64Split)!);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showUpdateDialog(context, service, store, offer, fromAutoCheck: true),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Version 1.5.0 is ready (you have 1.4.0)'), findsOneWidget);
    expect(find.text('New in 1.5.0'), findsOneWidget);
    await tester.tap(find.text('Skip this version'));
    await tester.pumpAndSettle();
    expect(find.text('Update'), findsNothing);
    expect(store.isSkipped(const Version(1, 5, 0)), isTrue);
  });
}
