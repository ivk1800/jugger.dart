import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../errors_glossary.dart';
import '../utils/utils.dart';

/// Checks the generated code for unused providers. These are providers that are
/// not used in the object graph.
void checkUnusedProviders(String content) {
  final CompilationUnit unit = parseString(content: content).unit;
  final _Visitor visitor = _Visitor(rawContent: content);
  unit.visitChildren(visitor);

  check(
    visitor.variables.isEmpty,
    () => buildErrorMessage(
      error: JuggerErrorId.unused_generated_providers,
      message:
          'Found unused generated providers: ${visitor.variables.join(', ')}',
    ),
  );
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor({
    required String rawContent,
  }) : _rawContent = rawContent;

  final String _rawContent;
  final List<String> _variables = <String>[];

  Iterable<String> get variables => _variables;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    final RegExp regExp = RegExp(node.name2.lexeme);
    final Iterable<RegExpMatch> allMatches = regExp.allMatches(_rawContent);
    if (allMatches.length == 1) {
      _variables.add(node.name2.lexeme);
    }
  }
}
