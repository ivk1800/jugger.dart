import 'package:freezed_annotation/freezed_annotation.dart';

import 'package_model.dart';

part 'packages_list_state.freezed.dart';

@freezed
@immutable
class PackagesListState with _$PackagesListState {
  const factory PackagesListState.loading() = PackagesListStateLoading;

  const factory PackagesListState.error({required String message}) =
      PackagesListStateError;

  const factory PackagesListState.data({
    required List<PackageModel> items,
  }) = PackagesListStateData;
}
