// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
import 'package:example3/example3.dart' as _i1;
import 'package:jugger/jugger.dart' as _i2;

class JuggerAppComponent implements _i1.AppComponent {
  JuggerAppComponent.create() {
    _init();
  }

  _i2.IProvider<dynamic> _iDataFormatterProvider;

  @override
  _i1.IDataFormatter getDataFormatter() {
    return _iDataFormatterProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _iDataFormatterProvider = _i2.SingletonProvider<dynamic>(() {
      return _i1.DataFormatter();
    });
  }

  @override
  void inject(_i1.MyClass target) {
    target.dataFormatter = _iDataFormatterProvider.get();
  }
}
