import 'package:hive_flutter/hive_flutter.dart';

/// Initializes Hive for future non-sensitive local preferences.
///
/// Authentication and business records are stored in Firebase. No passwords,
/// PINs, customer records, or mock data are persisted locally.
class StorageService {
  static Future<void> init() => Hive.initFlutter();
}
