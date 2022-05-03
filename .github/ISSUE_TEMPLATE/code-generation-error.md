---
name: Code generation error
about: If generation fails with your component and module
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

**Error result from terminal:**
```
// example
error: build method of ComponentBuilder return wrong type.
[INFO] Running build completed, took 834ms

[INFO] Caching finalized dependency graph...
[INFO] Caching finalized dependency graph completed, took 35ms

[SEVERE] Failed after 886ms

Process finished with exit code 1
```
**jugger version**
