import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final Directory filesDirectory =
      Directory('${Directory.current.path}/../lib');
  final Directory assetsDirectory =
      Directory('${Directory.current.path}/assets');
  final List<FileSystemEntity> entries =
      filesDirectory.listSync(recursive: true).toList();

  final Iterable<FileSystemEntity> where = entries
      .where((FileSystemEntity entity) => entity.path.endsWith('jugger.dart'));

  for (FileSystemEntity entity in where) {
    final String generateFilePath = entity.path;
    final String originalFilePath = entity.path.replaceAll('.jugger', '');
    final String testFilePath = (await File(originalFilePath)
            .openRead()
            .map(utf8.decode)
            .transform(const LineSplitter())
            .take(1)
            .first)
        .replaceAll('// ', '');

    final String testContent =
        await File('${assetsDirectory.path}/$testFilePath.txt').readAsString();
    final String generatedContent = await File(generateFilePath).readAsString();
    print('check: ${entity.path}');
    assert(testContent == generatedContent);
    print('ok');
  }
}
