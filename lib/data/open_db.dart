import 'package:drift_flutter/drift_flutter.dart';

import 'db.dart';

/// The app's on-device database (kept apart from db.dart so drift's schema tools can load it).
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'korean_cards'));
