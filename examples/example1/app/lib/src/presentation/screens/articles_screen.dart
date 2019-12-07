import 'package:example1/src/core/tracker.dart';
import 'package:example1/src/presentation/blocs/articles_screen_bloc.dart';
import 'package:example1/src/presentation/models/models.dart';
import 'package:example1/src/presentation/widgets/injector_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jugger/jugger.dart';

class ArticlesScreen extends StatefulWidget {
  @override
  ArticlesScreenState createState() => ArticlesScreenState();
}

class ArticlesScreenState extends State<ArticlesScreen> {
  @inject
  ArticlesBloc bloc;
  @inject
  Tracker tracker;
  @inject
  String token;

  @override
  void initState() {
    Injector.of(context).injectArticlesScreen(this);
    assert(bloc != null);
    super.initState();
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
      ),
      body: StreamBuilder<List<ArticleModel>>(
        stream: bloc.articles,
        builder:
            (BuildContext context, AsyncSnapshot<List<ArticleModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: const CircularProgressIndicator(),
            );
          }

          if (snapshot.error != null) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final List<ArticleModel> items = snapshot.data;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final ArticleModel item = items[index];

              return ListTile(
                onTap: () => bloc.articleClicked(item),
                title: Text(item.title),
                subtitle: Text(item.description),
              );
            },
          );
        },
      ),
    );
  }
}
