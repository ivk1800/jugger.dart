import 'package:bloc/bloc.dart';
import 'package:flutter_example/src/app/data/data.dart';
import 'package:flutter_example/src/common/logger.dart';
import 'package:flutter_example/src/di/scope.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_router.dart';
import 'package:jugger/jugger.dart' as j;

import 'package_model_mapper.dart';
import 'packages_list_event.dart';
import 'packages_list_state.dart';

@screenScope
class PackagesListBloc extends Bloc<PackagesListEvent, PackagesListState> {
  @j.inject
  PackagesListBloc({
    required IPackagesListScreenRouter router,
    required IPackagesRepository packagesRepository,
    required PackageModelMapper packageModelMapper,
    required Logger logger,
  })  : _router = router,
        _packagesRepository = packagesRepository,
        _packageModelMapper = packageModelMapper,
        _logger = logger,
        super(const PackagesListState.loading()) {
    on<PackagesListEventFetch>(_onFetchEvent);
    on<PackagesListEventPackageTap>(_onPackageTap);
    _logger.d('PackagesList showed');
  }

  // injected method example
  @j.inject
  void onInit() {
    add(const PackagesListEvent.fetch());
  }

  final IPackagesListScreenRouter _router;
  final IPackagesRepository _packagesRepository;
  final PackageModelMapper _packageModelMapper;
  final Logger _logger;

  Future<void> _onFetchEvent(
      PackagesListEventFetch event, Emitter<PackagesListState> emit) async {
    try {
      final List<Package> packages = await _packagesRepository.getPackages();
      emit(
        PackagesListState.data(
          items: _packageModelMapper.mapToPackageModels(packages),
        ),
      );
    } on Exception catch (e) {
      emit(PackagesListState.error(message: e.toString()));
    }
  }

  void _onPackageTap(
      PackagesListEventPackageTap event, Emitter<PackagesListState> emit) {
    _router.toPackageDetails(event.name);
  }
}
