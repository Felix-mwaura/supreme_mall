# Build-failure investigation and fix

**Branch:** `arena/926bcd60-supreme-mall` (from `main` @ `ef8955e`)
**Scope:** repair the build. No redesign, no navigation changes, no brand-colour
changes, no new Supabase work.

---

## 1. What was actually wrong

Two unrelated causes, one of them a single file.

### 1.1 Wrong relative depth in one file (the real compile error)

`lib/screens/home/tabs/home_tab.dart` sat three directories below `lib/`:

```
lib/screens/home/tabs/home_tab.dart
    ../          → lib/screens/home
    ../../       → lib/screens        ← what the file used
    ../../../    → lib                ← what it needed
```

So `../../models/department.dart` pointed at `lib/screens/models/department.dart`, which
does not exist. Its three sibling tabs in the same directory (`categories_tab.dart`,
`orders_tab.dart`, `profile_tab.dart`) all correctly use `../../../`, which is why only
this file broke.

Every other reported error is a **cascade from this one file**:

| Reported error | Real cause |
| --- | --- |
| `SupremeDepartment` / `supremeDepartments` undefined | `lib/screens/models/department.dart` does not exist; the real file is `lib/models/department.dart` |
| `AppColors` / `AppText` undefined | same, for `lib/theme/*` |
| `DarkSearchField` undefined | `lib/widgets/dark_surface.dart` was never imported (the path was wrong) |
| "Not a constant expression" | `const Icon(..., color: AppColors.gold)` etc. cannot be evaluated when `AppColors` does not resolve. Once the import is fixed the expressions are constant again — **no `const` was removed anywhere** |

### 1.2 Memory settings sized for a bigger machine

`android/gradle.properties` contained the Flutter template's high-memory defaults:

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m
```

That asks the Gradle daemon alone for an **8 GB heap plus 4 GB of metaspace** on an
**8 GB machine**. When Kotlin spawns its own daemon (it inherits similar sizing unless
overridden) and Flutter starts its Dart frontend server, the machine runs out of physical
memory and starts swapping — which is exactly the pair of errors reported:

- `Kotlin compiler daemon: Java heap space / exhausted heap`
- `Dart frontend compiler: Out of Memory`

Neither is a code problem, and neither is fixed by upgrading Gradle, Kotlin or AGP.

---

## 2. Files modified

| File | Change |
| --- | --- |
| `lib/screens/home/tabs/home_tab.dart` | Four imports corrected and switched to package imports |
| `android/gradle.properties` | JVM heaps sized for 8 GB; Kotlin daemon capped; parallel off |

```dart
// before
import '../../models/department.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/dark_surface.dart';

// after
import 'package:supreme_mall/models/department.dart';
import 'package:supreme_mall/theme/app_colors.dart';
import 'package:supreme_mall/theme/app_text.dart';
import 'package:supreme_mall/widgets/dark_surface.dart';
```

Only this one file changed. No other file had a broken import: all 170 import/export
directives in `lib/` and `test/` resolve to existing targets.

---

## 3. Missing components: none

`dark_surface.dart` **exists** (`lib/widgets/dark_surface.dart`) and `DarkSearchField`
**is defined in it** (line 112, `const DarkSearchField({...})`, used by both Home and
Categories). Nothing was created, so no duplicate widget was introduced:

- `DarkSearchField` — reused
- `DarkSectionLabel`, `DarkChip`, `DarkEmptyState`, `darkSurface()` — reused

---

## 4. Memory configuration for 8 GB

```properties
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m -XX:+HeapDumpOnOutOfMemoryError
kotlin.daemon.jvmargs=-Xmx1G
org.gradle.parallel=false
org.gradle.workers.max=2
org.gradle.caching=true
```

Budget on 8 GB: Gradle daemon 3 GB + Kotlin daemon 1 GB + Dart frontend ~1.5 GB + OS ≈ 7 GB.
If you also run an emulator (2 GB+), drop Gradle to `-Xmx2G`, or use a physical device.

**No version changes.** Current toolchain, left as found:

| Piece | Version |
| --- | --- |
| Gradle wrapper | 9.3.1 |
| Android Gradle Plugin | 9.1.1 |
| Kotlin | 2.4.0 |
| Java source/target | 17 |
| compileSdk / minSdk / targetSdk | from the Flutter SDK (`flutter.compileSdkVersion` etc.) |

AGP 9.1.1 needs JDK 17+, so check Android Studio → Settings → Build, Execution, Deployment
→ Build Tools → Gradle → **Gradle JDK** is 17 or 21. An older JDK 11 is the other common
cause of "unsupported class file version" style failures.

### Important: kill the old daemons first

A daemon started with `-Xmx8G` keeps running after the properties change. Stop it or the
old heap stays in use:

```bash
cd android && ./gradlew --stop && cd ..
```

---

## 5. What was verified here, and what was not

Verified statically in this environment (no Flutter/Dart SDK available):

- **Import resolution** — all 170 directives across 42 files resolve; 4 were broken before
  the fix, 0 after.
- **Symbol resolution** — for every file, each referenced project symbol is defined
  locally or imported. Before the fix this reported exactly
  `AppColors, AppText, DarkSearchField, SupremeDepartment` in `home_tab.dart`; after, 0.
- **No duplicate top-level names** anywhere in `lib/`.
- **Delimiter balance** — all 42 files.
- **Const constructors** — no `const` invocation targets a non-const constructor and no
  `const` expression contains `copyWith`, a lambda, or interpolation.

Not verified: `flutter clean`, `pub get`, `analyze`, `test`, `run`. There is no Dart or
Flutter SDK in this sandbox and no network route to download one. **The build is not
confirmed working until you run the commands in §6.**

---

## 6. Commands to confirm

```bash
cd android && ./gradlew --stop && cd ..   # drop the 8 GB daemon
flutter clean
flutter pub get
flutter analyze      # expect: No issues found!
flutter test         # expect: 27 tests passing
flutter run
```

If `flutter analyze` still reports anything, the message will name the exact file and
line — paste it and I will fix that specific case rather than guessing.
