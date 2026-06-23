import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1-based current page number. `0` when no document is open.
class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int pageNumber) => state = pageNumber;
}

final currentPageProvider =
    NotifierProvider<CurrentPageNotifier, int>(CurrentPageNotifier.new);

/// Current zoom ratio. `1.0` means fit-to-view. `0` when no document is open.
class CurrentZoomNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void set(double zoom) => state = zoom;
}

final currentZoomProvider =
    NotifierProvider<CurrentZoomNotifier, double>(CurrentZoomNotifier.new);
