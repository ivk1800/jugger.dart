import 'package:bloc/bloc.dart';
import 'package:flutter_example/src/app/data/data.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_router.dart';
import 'package:jugger/jugger.dart' as j;

import 'package_model_mapper.dart';
import 'packages_list_event.dart';
import 'packages_list_state.dart';

@j.singleton
class PackagesListBloc extends Bloc<PackagesListEvent, PackagesListState> {
  @j.inject
  PackagesListBloc({
    required IPackagesListScreenRouter router,
    required IPackagesRepository packagesRepository,
    required PackageModelMapper packageModelMapper,
  })  : _router = router,
        _packagesRepository = packagesRepository,
        _packageModelMapper = packageModelMapper,
        super(const PackagesListState.loading()) {
    on<PackagesListEventFetch>(_onFetchEvent);
    on<PackagesListEventPackageTap>(_onPackageTap);
  }

  // injected method example
  @j.inject
  void onInit() {
    add(const PackagesListEvent.fetch());
  }

  final IPackagesListScreenRouter _router;
  final IPackagesRepository _packagesRepository;
  final PackageModelMapper _packageModelMapper;

  Future<void> _onFetchEvent(
      PackagesListEventFetch event, Emitter<PackagesListState> emit) async {
    // TODO(Ivan): handle errors
    final List<Package> packages = await _packagesRepository.getPackages();

    emit(
      PackagesListState.data(
        items: _packageModelMapper.mapToPackageModels(packages),
      ),
    );
  }

  void _onPackageTap(
      PackagesListEventPackageTap event, Emitter<PackagesListState> emit) {
    _router.toPackageDetails(event.name);
  }
}
