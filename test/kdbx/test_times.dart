import 'package:kpasslib/src/kdbx/kdbx_time.dart';

/// Represents test times type
class TestTimes {
  DateTime? creation;
  DateTime? modification;
  DateTime? access;
  DateTime? expiry;
  DateTime? locationChange;
  bool? expires;
  int? usageCount;

  TestTimes(
      {this.creation,
      this.modification,
      this.access,
      this.expiry,
      this.locationChange,
      this.expires,
      this.usageCount});

  bool isEqual(KdbxTimes times) {
    return (creation == null ||
            creation!.isAtSameMomentAs(times.creation.timeOrZero)) &&
        (modification == null ||
            modification!.isAtSameMomentAs(times.modification.timeOrZero)) &&
        (access == null || access!.isAtSameMomentAs(times.access.timeOrZero)) &&
        (expiry == null || expiry!.isAtSameMomentAs(times.expiry.timeOrZero)) &&
        (locationChange == null ||
            locationChange!
                .isAtSameMomentAs(times.locationChange.timeOrZero)) &&
        (expires == null || expires == times.expires) &&
        (usageCount == null || usageCount == times.usageCount);
  }
}
