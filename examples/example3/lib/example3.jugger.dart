// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
// ignore_for_file: always_specify_types
// ignore_for_file: directives_ordering
import 'package:example3/example3.dart' as _i1;
import 'package:jugger/jugger.dart' as _i2;

class JuggerAuthScreenComponentBuilder
    implements _i1.AuthScreenComponentBuilder {
  _i1.AppComponent? _appComponent;

  _i1.AuthPageState? _authPageState;

  @override
  _i1.AuthScreenComponentBuilder appComponent(_i1.AppComponent component) {
    _appComponent = component;
    return this;
  }

  @override
  _i1.AuthScreenComponentBuilder screen(_i1.AuthPageState screen) {
    _authPageState = screen;
    return this;
  }

  @override
  _i1.AuthScreenComponent build() {
    assert(_appComponent != null);
    assert(_authPageState != null);
    return JuggerAuthScreenComponent._create(_appComponent!, _authPageState!);
  }
}

class JuggerAppComponent implements _i1.AppComponent {
  JuggerAppComponent.create() {
    _init();
  }

  late _i2.IProvider<_i1.IDataFormatter> _iDataFormatterProvider;

  @override
  _i1.IDataFormatter getDataFormatter() {
    return _iDataFormatterProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _iDataFormatterProvider = _i2.SingletonProvider<_i1.IDataFormatter>(() {
      return _i1.DataFormatter();
    });
  }

  @override
  void inject(_i1.MyClass target) {
    target.dataFormatter = _iDataFormatterProvider.get();
  }

  @override
  void dispose() {}
}

class JuggerAuthScreenComponent implements _i1.AuthScreenComponent {
  JuggerAuthScreenComponent._create(this._appComponent, this._authPageState) {
    _init();
  }

  late _i2.IProvider<_i1.AuthScreenViewModel> _authScreenViewModelProvider;

  late _i2.IProvider<_i1.ResultDispatcher<_i1.UserCredentials>>
      _resultDispatcherProvider;

  late _i2.IProvider<Map<int, List<String>>> _mapProvider;

  final _i1.AppComponent _appComponent;

  final _i1.AuthPageState _authPageState;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _authScreenViewModelProvider = _i2.Provider<_i1.AuthScreenViewModel>(() {
      return _i1.AuthScreenViewModel(
          _resultDispatcherProvider.get(), _mapProvider.get());
    });
    _resultDispatcherProvider =
        _i2.Provider<_i1.ResultDispatcher<_i1.UserCredentials>>(() {
      return _i1.AuthScreenModule.provideResultDispatcher(_authPageState);
    });
    _mapProvider = _i2.Provider<Map<int, List<String>>>(() {
      return _i1.AuthScreenModule.provideData();
    });
  }

  @override
  void inject(_i1.AuthPageState target) {
    target.viewModel = _authScreenViewModelProvider.get();
  }

  @override
  void dispose() {}
}

class JuggerAppComponent2 implements _i1.AppComponent2 {
  JuggerAppComponent2.create() {
    _init();
  }

  late _i2.IProvider<_i1.IChatUpdatesProvider> _iChatUpdatesProviderProvider;

  late _i2.IProvider<_i1.UpdatesProvider> _updatesProviderProvider;

  @override
  _i1.IChatUpdatesProvider getChatUpdatesProvider() {
    return _iChatUpdatesProviderProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _iChatUpdatesProviderProvider =
        _i2.SingletonProvider<_i1.IChatUpdatesProvider>(() {
      return _updatesProviderProvider.get();
    });
    _updatesProviderProvider = _i2.SingletonProvider<_i1.UpdatesProvider>(() {
      return _i1.Module.provideUpdatesProvider();
    });
  }

  @override
  void dispose() {}
}
