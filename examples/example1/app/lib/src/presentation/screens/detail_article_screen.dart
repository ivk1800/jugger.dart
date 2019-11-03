import 'package:example1/src/presentation/blocs/detail_article_screen_bloc.dart';
import 'package:example1/src/presentation/models/models.dart';
import 'package:example1/src/presentation/widgets/injector_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jugger/jugger.dart';

class DetailArticleScreen extends StatefulWidget {
  const DetailArticleScreen({Key key, @required this.articlesId})
      : super(key: key);

  final int articlesId;

  @override
  DetailArticleScreenState createState() => DetailArticleScreenState();
}

class DetailArticleScreenState extends State<DetailArticleScreen> {
  @inject
  DetailArticleBloc bloc;

  @override
  void initState() {
    Injector.of(context).injectDetailArticleScreen(this);
    bloc.setData(widget.articlesId);
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
        title: const Text('Article'),
      ),
      body: StreamBuilder<DetailArticleModel>(
        stream: bloc.article,
        builder:
            (BuildContext context, AsyncSnapshot<DetailArticleModel> snapshot) {
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

          final DetailArticleModel item = snapshot.data;

          return ListTile(
            title: Text(item.title),
            subtitle: Text(item.description),
          );
        },
      ),
    );
  }
}
