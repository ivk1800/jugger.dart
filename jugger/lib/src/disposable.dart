abstract class IDisposable {
  void dispose();
}

abstract class IDisposableBag implements IDisposable {
  void registerDisposable(IDisposable disposable);
}

mixin DisposableBagMixin implements IDisposableBag {
  final Set<IDisposable> _disposables = <IDisposable>{};

  @override
  void registerDisposable(IDisposable disposable) {
    _disposables.add(disposable);
  }

  @override
  void dispose() {
    for (IDisposable value in _disposables) {
      value.dispose();
    }
    _disposables.clear();
  }
}
