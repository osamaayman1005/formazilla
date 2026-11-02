# Plan: custom splits (any rotation, not just Push / Pull / Legs)

Status: **phases 1–4 done** (2 Nov 2026): splits model + migration, scoped suggestion, presets, switch / edit days, scrolling day picker. Phase 5 (first-launch split picker) is still open.

## Goal

Let the user train any split — Upper/Lower, Full body, Bro split, Arnold, or fully custom — with any number of days, and still get one-tap "next workout" suggestions. Push/Pull/Legs becomes just one preset.

## Terms

| Term | Meaning | Example |
| --- | --- | --- |
| **Split** | The cycle you follow. One is active at a time. | "Push Pull Legs", "Upper Lower" |
| **Day** | One step in the split's cycle, in order. | Push, Pull, Legs |
| **Rotation** | A variant of a day's exercises. A day has 1..n rotations that alternate. | Push A, Push B |
| **Session** | One workout done on a date, from one rotation. | Mon 2 Nov · Pull B |

## What already works (no change needed)

- `Day` is already data with a `position`, not a hard-coded enum.
- `suggestDay` / `suggestRotation` in `lib/domain/workout_logic.dart` already cycle through *any* ordered list of days and rotations.
- PRs, last-time values and progress are keyed by **exercise name**, so they survive any split change.

## What assumes PPL today (must change)

1. `lib/data/seed.dart` only seeds Push / Pull / Legs.
2. Home's day switcher (`_DaySwitcher`) is laid out for exactly 3 equal buttons.
3. There's no UI to add, rename, reorder or delete days.
4. Copy such as "Days cycle Push → Pull → Legs" in Templates.

## Data model changes (schema v3)

```
Split   { id, name, isActive, position }          // new
Day     { id, splitId, name, position, archived }  // + splitId, + archived
Rotation, Session, SetLog                          // unchanged
```

- **Migration v2 → v3:** create one split "Push Pull Legs" (active) and set `splitId` on all existing days. Old files keep loading, the same way v1 "rota" keys still load.
- Only one split is active. Switching splits never deletes anything.
- A day with history is **archived**, not deleted, so past sessions keep their label.

## Rules (pure Dart, `lib/domain`, with tests)

1. **Next day** = the day after the last finished session's day, within the **active split's** order. Sessions from other splits are ignored for the suggestion.
2. No history in the active split → its first day.
3. **Next rotation**: unchanged (alternate; single rotation is always used).
4. A split has **1–7 days**. A day needs at least one rotation to be started.
5. The suggestion stays a suggestion: any day or rotation is one tap away.
6. Rest days are not modelled. The suggestion is based on your last workout, not the calendar.

## Presets (offered when creating a split)

| Preset | Days |
| --- | --- |
| Push Pull Legs | Push · Pull · Legs |
| Upper / Lower | Upper · Lower |
| Full body | Full body (rotations A / B / C) |
| Bro split | Chest · Back · Shoulders · Arms · Legs |
| Arnold | Chest + Back · Shoulders + Arms · Legs |
| Custom | Empty; user adds days |

Each preset seeds starter rotations from the existing exercise library.

## UI changes

- **Templates tab → "Your split"**
  - Header shows the active split name with **Switch** and **Edit**.
  - Edit: add day, rename, drag to reorder, archive. Same patterns as the rotation detail screen.
- **New split sheet:** pick a preset card or Custom, then name it.
- **Home day switcher:**
  - 2–3 days → equal buttons (as today).
  - 4+ days → a horizontal scrolling row of chips, the suggested one scrolled into view.
  - Keep the sliding pill and the "Suggested" dashed outline.
- **Copy:** "Days cycle in order" instead of naming Push/Pull/Legs.
- **First launch (optional):** ask "What split do you follow?" with the preset cards. Default stays PPL if skipped.

## Build phases

1. **Model + migration**
   - Add `Split`, `Day.splitId`, `Day.archived`; schema v3 migration; store methods (add/rename/reorder/archive day, add/switch split).
   - Done when: old data loads into one PPL split; unit tests for migration pass.
2. **Rules**
   - Scope `suggestDay` to the active split; skip archived days.
   - Done when: tests cover 2-, 3- and 5-day splits, switching splits, archived days.
3. **Edit days UI**
   - Templates "Your split" header, edit days screen, presets sheet.
   - Done when: the user can turn PPL into Upper/Lower without losing history or PRs.
4. **Home switcher for N days**
   - Scrollable chips for 4+ days, sliding pill.
   - Done when: Bro split (5 days) is usable one-handed and the suggested day is always visible.
5. **Polish**
   - First-launch split picker, empty states, README update.

## Tests to add

- Migration v2 → v3 keeps every session, rotation and PR.
- `suggestDay` for 2-, 3-, 5-day splits; wrap-around; ignores other splits; skips archived days.
- Archiving a day with history keeps its sessions' labels.
- Switching split back and forth restores the previous split's suggestion.

## Out of scope

- Calendar scheduling (e.g. "Mon/Wed/Fri") and rest-day tracking.
- Sharing splits with friends.
- Per-split PRs (PRs stay global per exercise).
