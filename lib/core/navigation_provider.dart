import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab {
  academy(0),
  coach(1),
  health(2);

  final int indexValue;
  const AppTab(this.indexValue);
}

final navigationProvider = StateProvider<AppTab>((ref) => AppTab.academy);
