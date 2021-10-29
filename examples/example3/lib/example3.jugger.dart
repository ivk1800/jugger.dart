// ignore_for_file: implementation_imports
// ignore_for_file: prefer_const_constructors
// ignore_for_file: always_specify_types
// ignore_for_file: directives_ordering
import 'package:example3/bind/bind_from_another_module.dart' as _i1;
import 'package:example3/example3.dart' as _i2;
import 'package:jugger/jugger.dart' as _i3;

class JuggerAuthScreenComponentBuilder
    implements _i2.AuthScreenComponentBuilder {
  _i2.AppComponent? _appComponent;

  _i2.AuthPageState? _authPageState;

  @override
  _i2.AuthScreenComponentBuilder appComponent(_i2.AppComponent component) {
    _appComponent = component;
    return this;
  }

  @override
  _i2.AuthScreenComponentBuilder screen(_i2.AuthPageState screen) {
    _authPageState = screen;
    return this;
  }

  @override
  _i2.AuthScreenComponent build() {
    assert(_appComponent != null);
    assert(_authPageState != null);
    return JuggerAuthScreenComponent._create(_appComponent!, _authPageState!);
  }
}

class JuggerAppComponent implements _i2.AppComponent {
  JuggerAppComponent.create() {
    _init();
  }

  late _i3.IProvider<_i2.IDataFormatter> _iDataFormatterProvider;

  @override
  _i2.IDataFormatter getDataFormatter() {
    return _iDataFormatterProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _iDataFormatterProvider = _i3.SingletonProvider<_i2.IDataFormatter>(() {
      return _i2.DataFormatter();
    });
  }

  @override
  void inject(_i2.MyClass target) {
    target.dataFormatter = _iDataFormatterProvider.get();
  }

  @override
  void dispose() {}
}

class JuggerAuthScreenComponent implements _i2.AuthScreenComponent {
  JuggerAuthScreenComponent._create(this._appComponent, this._authPageState) {
    _init();
  }

  late _i3.IProvider<_i2.AuthScreenViewModel> _authScreenViewModelProvider;

  late _i3.IProvider<_i2.ResultDispatcher<_i2.UserCredentials>>
      _resultDispatcherProvider;

  late _i3.IProvider<Map<int, List<String>>> _mapProvider;

  final _i2.AppComponent _appComponent;

  final _i2.AuthPageState _authPageState;

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _authScreenViewModelProvider = _i3.Provider<_i2.AuthScreenViewModel>(() {
      return _i2.AuthScreenViewModel(
          _resultDispatcherProvider.get(), _mapProvider.get());
    });
    _resultDispatcherProvider =
        _i3.Provider<_i2.ResultDispatcher<_i2.UserCredentials>>(() {
      return _i2.AuthScreenModule.provideResultDispatcher(_authPageState);
    });
    _mapProvider = _i3.Provider<Map<int, List<String>>>(() {
      return _i2.AuthScreenModule.provideData();
    });
  }

  @override
  void inject(_i2.AuthPageState target) {
    target.viewModel = _authScreenViewModelProvider.get();
  }

  @override
  void dispose() {}
}

class JuggerAppComponent2 implements _i2.AppComponent2 {
  JuggerAppComponent2.create() {
    _init();
  }

  late _i3.IProvider<_i2.UpdatesProvider> _updatesProviderProvider;

  late _i3.IProvider<_i2.IChatUpdatesProvider> _iChatUpdatesProviderProvider;

  @override
  _i2.IChatUpdatesProvider getChatUpdatesProvider() {
    return _iChatUpdatesProviderProvider.get();
  }

  void _init() {
    _initProvides();
  }

  void _initProvides() {
    _updatesProviderProvider = _i3.SingletonProvider<_i2.UpdatesProvider>(() {
      return _i2.Module.provideUpdatesProvider();
    });
    _iChatUpdatesProviderProvider =
        _i3.SingletonProvider<_i2.IChatUpdatesProvider>(() {
      return _updatesProviderProvider.get();
    });
  }

  @override
  void dispose() {}
}
