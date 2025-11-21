import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/business_profile.dart';

class BusinessProvider with ChangeNotifier {
  BusinessProfile? _businessProfile;
  static const String _boxName = 'business_profile';

  BusinessProfile? get businessProfile => _businessProfile;

  bool get hasBusinessProfile => _businessProfile != null;

  Future<void> loadBusinessProfile() async {
    var box = await Hive.openBox<BusinessProfile>(_boxName);
    if (box.isNotEmpty) {
      _businessProfile = box.getAt(0);
    }
    notifyListeners();
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    var box = await Hive.openBox<BusinessProfile>(_boxName);
    await box.clear(); // Only one profile allowed
    await box.add(profile);
    _businessProfile = profile;
    notifyListeners();
  }

  Future<void> updateBusinessProfile(BusinessProfile profile) async {
    // Since it's a HiveObject, we can technically just save(), but let's be explicit
    await saveBusinessProfile(profile);
  }
}
