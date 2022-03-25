import 'package:freezed_annotation/freezed_annotation.dart';

part 'packages_list_event.freezed.dart';

@freezed
@immutable
class PackagesListEvent with _$PackagesListEvent {
  const factory PackagesListEvent.fetch() = PackagesListEventFetch;
  const factory PackagesListEvent.packageTap({required String name}) =
      PackagesListEventPackageTap;
}
