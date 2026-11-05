# Sticker-album redesign: function coverage

The redesign changes **looks and usability only**. Every action the app supports today keeps working. This table maps each `AppStore` action to the redesigned screen and control that triggers it. Design: `DESIGN.md`. Mockups: the "Formazilla redesign" design canvas.

## Rules for the build

- No change to `lib/data` models, `formazilla.json`, `schemaVersion` (4) or the signing key. A new APK installs over the old one and keeps all data.
- `lib/domain` and `lib/state` stay as they are. The redesign touches `lib/core/theme.dart` and `lib/ui` only.
- `flutter test` must pass before merge, and every row below is checked by hand on a phone that has real data.
- Ship it by installing it over the current build on a phone with history, then check that workouts, PRs and plans are all still there.

## Coverage

| Area | Action (`AppStore`) | Screen → control |
|---|---|---|
| Splits | `setActiveSplit` | Home → split button → Your splits → radio |
| | `createSplit` | Your splits → New split → preset or Custom |
| | `renameSplit` | Edit days → Rename |
| | `archiveSplit` | Edit days → Remove this split |
| Days | `addDay` | Edit days → name field → Add day |
| | `renameDay` | Edit days → pencil |
| | `reorderDays` | Edit days → drag handle |
| | `archiveDay` | Edit days → × |
| Start | `startSession` | Home → Start Pull B · Rotation → Start Push A |
| | `startOneTime` | Home → One-time workout |
| | `renameOneTime` | One-time workout → title → Rename (same sheet pattern as Exercise options) |
| | `discardSession` | Home (workout open) → Discard · Finish with nothing logged → confirm |
| Workout | `switchRotation` | Workout → A / B segmented button |
| | `addExercise` (incl. cardio) | Workout → Add exercise sheet → result or cardio chip |
| | `setCardioMinutes` | Workout → cardio sticker → keypad (minutes) |
| | `renameExercise` | Workout → Edit → Rename |
| | `moveExerciseGroup` | Workout → drag handle on Up next rows · Edit → Move up/down |
| | `removeExercise` / `insertExercise` | Workout → Edit → Remove → snackbar Undo |
| | `linkSuperset` | Workout → Superset → Superset with… → Link |
| | `unlinkSuperset` | Workout → superset group → Unlink |
| Sets | `addSet` (same weight) | Workout → outlined last-time slot (one tap, no keypad) |
| | `addSet` (new weight) | Workout → + slot → clean keypad → Save |
| | `updateSet` | Workout → logged sticker → keypad with that weight selected → Save |
| | `removeSet` | Logged sticker → keypad → Delete set (Undo snackbar) |
| | `toggleDropSet` | Keypad → Drop set |
| Finish | `finishSession` | Workout → Finish → Workout saved (today's page, Share a PR, Done) |
| History | `deleteSession` | Past workout → Delete workout |
| | edit past workout | Past workout → Edit (reopens in the workout screen) |
| | `exportJson` | History → Backup → Copy backup |
| | `importJson` | History → Backup → Restore (confirm; non-Formazilla text refused) |
| Templates | `addRotation` | Templates → Add a rotation to Push |
| | `renameRotation` / `duplicateRotation` / `deleteRotation` | Templates → ⋮ → Rename / Duplicate / Delete |
| | `addRotationExercise` | Rotation → Add exercise field or quick-add chip |
| | `removeRotationExercise` | Rotation → × |
| | `reorderRotationExercise` | Rotation → drag handle |
| Share | `planForRotation` / `planForSplit` | Templates or Rotation → Share → Push A / Whole split → Image card, Message, QR code |
| | `importIntoDay` / `importAsSplit` | Templates → Import → Scan QR or Paste → Add it as… → Import |
| Progress | PRs, best, history, chart | Progress → exercise → Exercise progress · PR card → Share or save |
| Home | suggested day and rotation | Home headline and Suggested tiles (any tile switches) |

## Changed on purpose

- **+ opens a clean keypad.** No weight is prefilled, so a new number is typed without erasing anything. Last time is shown as a hint only.
- **Hidden gestures became buttons.** Long-press for drop set, ⋮ for superset, and hold-to-move now have labelled buttons or visible handles. The old gestures can stay as shortcuts.
