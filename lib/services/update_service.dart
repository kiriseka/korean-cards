import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app updates from the GitHub releases of kiriseka/korean-cards.
///
/// The version comes from the APK names (`korean-cards-1.5.0-arm64.apk`), not the tag, because
/// older releases use tags like `Latest` and `Stable`. The native half (version info, install
/// permission, opening the system installer) is in MainActivity.kt.
const releasesUrl = 'https://api.github.com/repos/kiriseka/korean-cards/releases?per_page=10';
const _userAgent = 'korean-cards-app';

class Version implements Comparable<Version> {
  const Version(this.major, this.minor, this.patch);
  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^[vV]?(\d+)\.(\d+)\.(\d+)');

  /// Reads `1.4.0`, `V1.4.0` or `1.4.0+5`; null for anything else.
  static Version? tryParse(String? text) {
    final m = _pattern.firstMatch(text?.trim() ?? '');
    if (m == null) return null;
    return Version(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  @override
  int compareTo(Version other) => major != other.major
      ? major - other.major
      : minor != other.minor
          ? minor - other.minor
          : patch - other.patch;

  bool operator >(Version other) => compareTo(other) > 0;
  bool operator >=(Version other) => compareTo(other) >= 0;
  bool operator <=(Version other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

enum ApkVariant { arm64, armv7, universal }

class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.url, required this.size, required this.sha256, required this.version, required this.variant});
  final String name;
  final String url;
  final int size;

  /// Lower-case hex SHA-256 from GitHub's `digest` field, when it has one.
  final String? sha256;
  final Version version;
  final ApkVariant variant;

  static final _pattern = RegExp(r'^korean-cards-(\d+\.\d+\.\d+)-(arm64|armv7|universal)\.apk$');

  static ReleaseAsset? fromJson(Map<String, dynamic> json) {
    final m = _pattern.firstMatch(json['name'] as String? ?? '');
    final url = json['browser_download_url'] as String?;
    if (m == null || url == null) return null;
    final digest = json['digest'] as String?;
    return ReleaseAsset(
      name: m[0]!,
      url: url,
      size: (json['size'] as num?)?.toInt() ?? 0,
      sha256: digest != null && digest.startsWith('sha256:') ? digest.substring(7).toLowerCase() : null,
      version: Version.tryParse(m[1])!,
      variant: ApkVariant.values.byName(m[2]!),
    );
  }
}

/// The newest release on GitHub.
class AvailableUpdate {
  const AvailableUpdate({required this.version, required this.notes, required this.htmlUrl, required this.assets});
  final Version version;
  final String notes;
  final String htmlUrl;
  final List<ReleaseAsset> assets;
}

/// What is installed on this phone (from MainActivity.kt).
class AppInfo {
  const AppInfo({required this.versionName, required this.versionCode, required this.abis});
  final String versionName;

  /// `--split-per-abi` builds add 1000 × ABI to the build number (armv7 1xxx, arm64 2xxx);
  /// the universal APK keeps the plain build number.
  final int versionCode;
  final List<String> abis;

  Version get version => Version.tryParse(versionName) ?? const Version(0, 0, 0);
  bool get isSplit => versionCode >= 1000;
}

/// An update this phone can install.
class UpdateOffer {
  const UpdateOffer({required this.current, required this.release, required this.apk});
  final Version current;
  final AvailableUpdate release;
  final ReleaseAsset apk;
  Version get version => release.version;
}

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UpdateCancelled implements Exception {
  const UpdateCancelled();
}

class CancelToken {
  bool cancelled = false;
  void cancel() => cancelled = true;
}

enum InstallResult { started, needsPermission }

/// The highest-version published release (not a draft or prerelease) that has APKs.
AvailableUpdate? latestRelease(List<dynamic> releases) {
  AvailableUpdate? best;
  for (final r in releases.whereType<Map<String, dynamic>>()) {
    if (r['draft'] == true || r['prerelease'] == true) continue;
    final assets = [
      for (final a in (r['assets'] as List? ?? const []).whereType<Map<String, dynamic>>()) ?ReleaseAsset.fromJson(a),
    ];
    if (assets.isEmpty) continue;
    final version = assets.map((a) => a.version).reduce((a, b) => a > b ? a : b);
    if (best != null && best.version >= version) continue;
    best = AvailableUpdate(
      version: version,
      notes: (r['body'] as String? ?? '').trim(),
      htmlUrl: r['html_url'] as String? ?? 'https://github.com/kiriseka/korean-cards/releases',
      assets: [for (final a in assets) if (a.version == version) a],
    );
  }
  return best;
}

/// The APK that installs over what is on this phone. A universal APK can't replace a split one
/// (its version code is lower), so split installs only get the APK for the phone's own ABI.
ReleaseAsset? pickAsset(AvailableUpdate update, AppInfo app) {
  final want = switch (app.abis.firstOrNull) {
    'arm64-v8a' => ApkVariant.arm64,
    'armeabi-v7a' => ApkVariant.armv7,
    _ => null,
  };
  ReleaseAsset? find(ApkVariant v) => update.assets.where((a) => a.variant == v).firstOrNull;
  final match = want == null ? null : find(want);
  if (app.isSplit) return match;
  return match ?? find(ApkVariant.universal);
}

class UpdateService {
  UpdateService(this._client, {this.downloadDir, this.channel = defaultChannel});

  static const defaultChannel = MethodChannel('korean_cards/update');

  final http.Client _client;

  /// Where APKs are downloaded; the app's cache/updates/ (see res/xml/update_paths.xml) by default.
  final Directory? downloadDir;
  final MethodChannel channel;

  /// Null in tests and on platforms without the native side.
  Future<AppInfo?> appInfo() async {
    try {
      final m = await channel.invokeMapMethod<String, dynamic>('appInfo');
      if (m == null) return null;
      return AppInfo(
        versionName: m['versionName'] as String? ?? '0.0.0',
        versionCode: (m['versionCode'] as num?)?.toInt() ?? 0,
        abis: [for (final a in m['abis'] as List? ?? const []) a as String],
      );
    } on MissingPluginException {
      return null;
    }
  }

  /// The update for this phone, or null when it is up to date.
  Future<UpdateOffer?> check(AppInfo app) async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(releasesUrl), headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const UpdateException("Couldn't reach GitHub. Check your internet connection.");
    } on Exception {
      throw const UpdateException("Couldn't check for updates. Check your internet connection.");
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw const UpdateException('GitHub is busy right now. Try again in an hour.');
    }
    if (response.statusCode != 200) {
      throw UpdateException("Couldn't check for updates (GitHub said ${response.statusCode}).");
    }
    final AvailableUpdate? latest;
    try {
      latest = latestRelease(jsonDecode(utf8.decode(response.bodyBytes)) as List);
    } on Object {
      throw const UpdateException("Couldn't read the release list from GitHub.");
    }
    if (latest == null || latest.version <= app.version) return null;
    final apk = pickAsset(latest, app);
    if (apk == null) {
      throw UpdateException('Version ${latest.version} is out, but has no APK for this phone. Get it from GitHub: ${latest.htmlUrl}');
    }
    return UpdateOffer(current: app.version, release: latest, apk: apk);
  }

  Future<Directory> _dir() async => downloadDir ?? Directory('${(await getTemporaryDirectory()).path}/updates');

  /// Downloads [apk] into the cache and checks its size and SHA-256.
  Future<File> download(ReleaseAsset apk, {void Function(int received, int total)? onProgress, CancelToken? cancel}) async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final file = File('${dir.path}/${apk.name}');

    final http.StreamedResponse response;
    try {
      response = await _client
          .send(http.Request('GET', Uri.parse(apk.url))..headers['User-Agent'] = _userAgent)
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw const UpdateException("Couldn't start the download. Check your internet connection.");
    }
    if (response.statusCode != 200) {
      throw UpdateException('The download failed (GitHub said ${response.statusCode}).');
    }

    final total = apk.size > 0 ? apk.size : (response.contentLength ?? 0);
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    final sink = file.openWrite();
    var received = 0;
    var ok = false;
    try {
      await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
        if (cancel?.cancelled ?? false) throw const UpdateCancelled();
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      hasher.close();
      if (apk.size > 0 && received != apk.size) {
        throw const UpdateException('The download was cut off. Please try again.');
      }
      if (apk.sha256 != null && digest.value.toString() != apk.sha256) {
        throw const UpdateException('The download was damaged. Please try again.');
      }
      ok = true;
    } on UpdateCancelled {
      rethrow;
    } on UpdateException {
      rethrow;
    } on Exception {
      throw const UpdateException('The download stopped. Check your internet connection and try again.');
    } finally {
      await sink.close();
      if (!ok && await file.exists()) await file.delete();
    }
    return file;
  }

  /// Opens Android's installer, unless Korean Cards isn't allowed to install apps yet.
  Future<InstallResult> install(File apk) async {
    final allowed = await channel.invokeMethod<bool>('canInstall') ?? false;
    if (!allowed) return InstallResult.needsPermission;
    await channel.invokeMethod('installApk', {'path': apk.path});
    return InstallResult.started;
  }

  /// The "Install unknown apps" switch for Korean Cards.
  Future<void> openInstallSettings() => channel.invokeMethod('openInstallSettings');

  /// Removes downloaded APKs.
  Future<void> cleanUp() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object {
      // Nothing to clean, or no file system (tests).
    }
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}

/// Update bookkeeping kept in SharedPreferences (not user settings).
class UpdateStore {
  UpdateStore(this._prefs);
  final SharedPreferences _prefs;

  static const checkEvery = Duration(hours: 24);

  /// How long a finished download is offered again after Android restarted the app
  /// (it can when "Install unknown apps" is switched on).
  static const pendingFor = Duration(hours: 1);

  bool dueForCheck(DateTime now) {
    final last = _prefs.getInt('updateLastCheck');
    return last == null || now.difference(DateTime.fromMillisecondsSinceEpoch(last)) >= checkEvery;
  }

  Future<void> markChecked(DateTime now) => _prefs.setInt('updateLastCheck', now.millisecondsSinceEpoch);

  bool isSkipped(Version v) {
    final skipped = Version.tryParse(_prefs.getString('updateSkippedVersion'));
    return skipped != null && v <= skipped;
  }

  Future<void> skip(Version v) => _prefs.setString('updateSkippedVersion', '$v');

  /// A verified download waiting to be installed, if it is recent.
  ({String path, Version version})? pending(DateTime now) {
    final path = _prefs.getString('updatePendingPath');
    final version = Version.tryParse(_prefs.getString('updatePendingVersion'));
    final at = _prefs.getInt('updatePendingAt');
    if (path == null || version == null || at == null) return null;
    if (now.difference(DateTime.fromMillisecondsSinceEpoch(at)) > pendingFor) return null;
    return (path: path, version: version);
  }

  Future<void> setPending(String path, Version version, DateTime now) async {
    await _prefs.setString('updatePendingPath', path);
    await _prefs.setString('updatePendingVersion', '$version');
    await _prefs.setInt('updatePendingAt', now.millisecondsSinceEpoch);
  }

  Future<void> clearPending() async {
    await _prefs.remove('updatePendingPath');
    await _prefs.remove('updatePendingVersion');
    await _prefs.remove('updatePendingAt');
  }
}
