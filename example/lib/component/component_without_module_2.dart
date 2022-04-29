import 'package:jugger/jugger.dart';

class Firebase {
  @inject
  const Firebase();
}

class Flurry {
  @inject
  const Flurry();
}

class Tracker {
  @inject
  const Tracker({
    required this.firebase,
    required this.flurry,
  });

  final Firebase firebase;
  final Flurry flurry;
}

@Component()
abstract class AppComponent {
  Tracker getTracker();
}
