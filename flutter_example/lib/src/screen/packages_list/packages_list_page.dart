import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_bloc.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_event.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_screen_scope.dart';
import 'package:flutter_example/src/screen/packages_list/packages_list_state.dart';

import 'package_model.dart';

class PackagesListPage extends StatelessWidget {
  const PackagesListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('packages'),
      ),
      body: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesListBloc, PackagesListState>(
      builder: (BuildContext context, PackagesListState state) {
        return state.map(
          loading: (_) {
            return const Center(child: CircularProgressIndicator());
          },
          data: (PackagesListStateData data) {
            return _Data(data: data);
          },
          error: (PackagesListStateError value) {
            return Center(child: Text(value.message));
          },
        );
      },
    );
  }
}

class _Data extends StatelessWidget {
  const _Data({
    Key? key,
    required this.data,
  }) : super(key: key);

  final PackagesListStateData data;

  @override
  Widget build(BuildContext context) {
    final PackagesListBloc bloc =
        PackagesListScreenScope.getPackagesListBloc(context);

    return ListView.builder(
      itemCount: data.items.length,
      itemBuilder: (BuildContext context, int index) {
        final PackageModel model = data.items[index];
        return ListTile(
          onTap: () => bloc.add(
            PackagesListEvent.packageTap(
              name: model.name,
            ),
          ),
          title: Text(model.name),
          subtitle: Text(model.shortDescription),
        );
      },
    );
  }
}
