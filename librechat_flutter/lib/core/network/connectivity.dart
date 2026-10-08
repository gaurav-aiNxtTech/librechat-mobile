import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [results] from connectivity_plus mean the device is online. It is
/// offline only when every result is [ConnectivityResult.none]; an empty list
/// counts as online so an unknown state never shows the offline banner.
bool isOnline(List<ConnectivityResult> results) =>
    results.isEmpty || results.any((r) => r != ConnectivityResult.none);

/// The device's network connectivity, for the offline banner (Req 14.8):
/// the current state first, then every change.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isOnline);
});
