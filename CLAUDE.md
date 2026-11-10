# Formazilla

Offline Flutter gym logger: PPL days, A/B rotations, one-tap set logging, automatic PRs.

- Full product spec: Claude Doc "Formazilla – Build Plan" (https://claude.ai/artifact/6ASXHr2hJGNEFwYugSTpqQ)
- Design: Figma "Gym Tracker – App Design" (https://www.figma.com/design/bZqhPpEgsoWZtslDjVC8wS)

## Architecture (v1 as built)

v1 deliberately uses zero codegen and few dependencies (`path_provider`, `share_plus`, `qr_flutter`, `mobile_scanner`) so it builds reliably in CI.
The plan's Drift/Riverpod stack is a later migration; the layers below make that a contained change.

```
lib/
  main.dart                 opens storage + store, runs app
  app.dart                  MaterialApp + bottom-nav shell
  core/                     theme tokens (theme.dart), formatting (format.dart)
  data/                     models, seed data, storage (JSON file; MemoryStorage for tests)
  domain/workout_logic.dart pure rules: next day/rotation, PRs, last-time values, search
  domain/shared_plan.dart   share/import format: readable message + `FZ2:` code (gzip; also the QR content)
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
- Edits inside a plan workout are permanent: add, remove, reorder and rename also update the rotation template (and rename updates history too).
- A one-time workout counts for PRs (same exercise name) and History only: suggestions, last-time values and Progress read `planWorkouts`.
- Cardio is any name in `AppData.cardio`; it's logged as minutes (one time button), never as sets, and has no PRs or supersets.
- Suggestions never enforce: any day/rotation is one tap away.
- A **split** holds ordered **days**; each day has 1+ **rotations**. Only the active split's history drives the next-day suggestion. Removing a split/day archives it so past workouts keep their names.
- `android/` is generated in CI (`flutter create .`). Locally run `flutter create . --platforms android` once.
- Every APK must be signed with `ci/signing.keystore` (CI patches Gradle and checks the cert). A different key forces an uninstall, which wipes the user's data.

## Roadmap

- Custom splits: `docs/plans/custom-splits.md` (phases 1–4 done; first-launch picker open)
- One-time workouts: built (`Session.oneTime`). Exercises added mid-workout stay in that workout only. Rename is always permanent.

## Build

Push to `main` → GitHub Actions analyzes, tests, builds `formazilla.apk` and publishes it under Releases.
A failed build opens an issue with the error log.

### Web version (iPhone)

- `.github/workflows/web.yml`: runs the tests in Chrome, builds web, publishes to GitHub Pages: https://osamaayman1005.github.io/formazilla/ (iPhone: Safari → Share → Add to Home Screen). It also pushes the build to the `web-build` branch for browser testing.
- `web/` is committed (icons, manifest, `sw.js` offline worker filled in by CI); the rest of the platform files are generated.
- Platform splits use conditional exports, never `dart:io` in shared code: `data/platform_storage.dart` (file on phones, localStorage on web) and `core/gzip.dart` (dart:io vs `archive`). Plan codes must stay readable across both (`test/gzip_compat_test.dart`).
- Check web changes with `kIsWeb`; the Android path must stay as it was.
