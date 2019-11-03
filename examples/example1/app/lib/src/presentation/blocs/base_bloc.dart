import 'dart:async';

import 'package:rxdart/rxdart.dart';

class BaseBloc {

  final CompositeSubscription _compositeSubscription = CompositeSubscription();

  void init() {}

  void dispose() {
    _compositeSubscription.dispose();
  }

  StreamSubscription<T> register<T>(StreamSubscription<T> subscription) {
    return _compositeSubscription.add(subscription);
  }
}
