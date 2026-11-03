# Formazilla

Offline Flutter gym logger: PPL days, A/B rotations, one-tap set logging, automatic PRs.

- Full product spec: Claude Doc "Formazilla – Build Plan" (https://claude.ai/artifact/6ASXHr2hJGNEFwYugSTpqQ)
- Design: Figma "Gym Tracker – App Design" (https://www.figma.com/design/bZqhPpEgsoWZtslDjVC8wS)

## Architecture (v1 as built)

v1 deliberately uses zero codegen and two small dependencies (`path_provider`, `share_plus`) so it builds reliably in CI.
The plan's Drift/Riverpod stack is a later migration; the layers below make that a contained change.

```
lib/
  main.dart                 opens storage + store, runs app
  app.dart                  MaterialApp + bottom-nav shell
  core/                     theme tokens (theme.dart), formatting (format.dart)
  data/                     models, seed data, storage (JSON file; MemoryStorage for tests)
  domain/workout_logic.dart pure rules: next day/rotation, PRs, last-time values, search
  domain/shared_plan.dart   share/import format: readable message + `FZ1:` code line
  state/app_store.dart      ChangeNotifier; the ONLY place data changes; autosaves
  ui/
    navigation.dart         all routes
    widgets/                SetChip, keypad sheet, exercise autocomplete, common pieces
    screens/                home, session, progress, exercise detail, templates, rotation detail, history
test/                       logic unit tests + widget/store tests
```

## Rules

- Business rules live in `lib/domain` as pure Dart with tests. UI never computes PRs or suggestions itself.
- UI reads via `StoreScope.of(context)` and changes data only through `AppStore` methods.
- Colours, spacing, radii and text styles come from `lib/core/theme.dart`. No hardcoded colours in widgets.
- Weights are unitless numbers stored exactly as typed. Never convert units.
- Suggestions never enforce: any day/rotation is one tap away.
- A **split** holds ordered **days**; each day has 1+ **rotations**. Only the active split's history drives the next-day suggestion. Removing a split/day archives it so past workouts keep their names.
- `android/` is generated in CI (`flutter create .`). Locally run `flutter create . --platforms android` once.
- Every APK must be signed with `ci/signing.keystore` (CI patches Gradle and checks the cert). A different key forces an uninstall, which wipes the user's data.

## Roadmap

- Custom splits: `docs/plans/custom-splits.md` (phases 1–4 done; first-launch picker open)
- One-time exercises: when adding mid-workout, choose "just today" vs "add to template" (today it's always just today). Rename is always permanent.

## Build

Push to `main` → GitHub Actions analyzes, tests, builds `formazilla.apk` and publishes it under Releases.
A failed build opens an issue with the error log.
