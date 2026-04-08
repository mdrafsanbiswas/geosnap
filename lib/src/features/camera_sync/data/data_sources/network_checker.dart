import 'dart:async';
import 'dart:io';

abstract class NetworkCheckerDataSource {
  Future<bool> hasNetworkAccess();

  Stream<bool> watchNetworkAccess();
}

class InternetLookupNetworkCheckerDataSource
    implements NetworkCheckerDataSource {
  InternetLookupNetworkCheckerDataSource({
    this.host = 'one.one.one.one',
    this.checkInterval = const Duration(seconds: 6),
  });

  final String host;
  final Duration checkInterval;

  @override
  Future<bool> hasNetworkAccess() async {
    try {
      final lookup = await InternetAddress.lookup(host).timeout(
        const Duration(seconds: 2),
      );
      return lookup.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> watchNetworkAccess() async* {
    bool? lastValue;
    while (true) {
      final currentValue = await hasNetworkAccess();
      if (lastValue == null || currentValue != lastValue) {
        lastValue = currentValue;
        yield currentValue;
      }
      await Future<void>.delayed(checkInterval);
    }
  }
}
