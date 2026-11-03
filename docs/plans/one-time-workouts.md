# One-time workouts

A workout that isn't part of any plan: a hotel gym, a session with a friend,
a "just arms today". Started from Home, never saved to a split or template,
but it shows up in History and its sets count for PRs and Progress.

It's **per workout, not per exercise**: exercises added inside a normal
workout already stay in that workout only.

## What the user sees

1. **Home**: under the Start card, a small secondary link: `+ One-time workout`.
   It never competes with the suggested day.
2. **Session screen**: same logger, empty to start, titled "One-time" (can be
   renamed, e.g. "Hotel gym"). No A/B switch. Add exercises and cardio as usual.
3. **Finish**: same summary and PRs. Nothing is written to any template.
4. **History**: listed with the other workouts, marked with a small
   "One-time" pill.

## Rules

- A one-time workout never moves the next-day suggestion (Push → Pull still
  follows plan workouts only).
- Its sets count for PRs, last-time ghost values and Progress, like any other
  workout (an exercise is the same exercise wherever it's done).
- Only one open workout at a time, as today.
- Optional later: "Save as rotation…" on the History detail, to turn a
  one-time workout into a template if it was good.

## Data

- `Session.dayId` / `rotationId` become nullable; one-time sessions have both
  null and a `title` (default "One-time"). Schema v5 (older files load as is).
- `suggestDay` / `suggestRotation` / `lastDoneAt` already filter by day ids,
  so null-day sessions are ignored; add a test to lock that in.
- `rotationLabel` falls back to the session title.

## Phases

1. Data + rules: nullable day/rotation, title, suggestion ignores them (tests).
2. Start from Home, session screen without A/B, History pill.
3. Optional: "Save as rotation…" from History.
