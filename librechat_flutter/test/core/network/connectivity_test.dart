import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/connectivity.dart';

/// The offline rule behind the offline banner (Req 14.8).
void main() {
  test('offline only when every result is none', () {
    expect(isOnline([ConnectivityResult.none]), isFalse);
    expect(
      isOnline([ConnectivityResult.none, ConnectivityResult.none]),
      isFalse,
    );
  });

  test('any real connection is online', () {
    expect(isOnline([ConnectivityResult.wifi]), isTrue);
    expect(
      isOnline([ConnectivityResult.mobile, ConnectivityResult.none]),
      isTrue,
    );
    expect(isOnline([ConnectivityResult.vpn]), isTrue);
  });

  test('no result counts as online', () {
    expect(isOnline([]), isTrue);
  });
}
