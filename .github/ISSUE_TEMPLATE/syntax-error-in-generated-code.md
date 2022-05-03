---
name: Syntax error in generated code
about: Generation succeeded, but the code does not compile
title: ''
labels: ''
assignees: ''

---

**Describe the error:**

**Code for reproduce:**
```dart
// example
import 'package:jugger/jugger.dart';

@Component()
abstract class AppComponent {
  String get string;
}

@componentBuilder
abstract class ComponentBuilder {
  ComponentBuilder setInt(int i);
  ComponentBuilder build();
}
```

**jugger version**
