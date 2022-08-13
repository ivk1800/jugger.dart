import '../generator/component_context.dart';
import '../generator/wrappers.dart';
import 'list_ext.dart';

extension SourceExt on ProviderSource {
  bool get isMultibindings {
    return annotations.any(
      (Annotation annotation) =>
          annotation is IntoSetAnnotation || annotation is IntoMapAnnotation,
    );
  }

  bool get isScoped => annotations.anyInstance<SingletonAnnotation>();
}
