---
version: 1
slug: "lib-ui"
primary_target: "lib/ui"
related_targets: []
---

Scope: every screen of the Formazilla Android app (Home, Workout, set keypad, add exercise, finish, History, past workout, Progress, exercise progress, PR card, Templates, rotation, edit days, splits, share, import, plan QR). Mode: Operate. Delivered as a design canvas (Figma plan limit reached); the Flutter build follows later.

Audience and task: an Egyptian lifter logging sets one-handed between sets, in a crowded gym, often a basement under fluorescent light. Success: a set is logged in one tap, the next workout is obvious, a PR is noticed the moment it happens.

Constraints: navy colours, dino logo and mascot, the four tabs (Home, History, Progress, Templates) and ease of use stay. Must not look like a generic AI app; no hidden gestures, fewest taps. No new features. English only. Material 3 structure and controls. UI only: data models, formazilla.json (schema v4) and the signing key stay unchanged, so no data is erased. Logging: the printed "last time" slot logs in one tap with no keypad; + opens a clean, empty keypad; a logged sticker opens the keypad with its own value to edit or delete.

Chosen direction: Sticker album. Memorable moment: tapping the printed slot sticks a white sticker; beating a PR sticks a foil one.

Unresolved: Flutter implementation of the sticker settle motion; whether the PR share card keeps the mascot.

## Direction contract

THESIS: Your workout is a page in a football sticker album: every set is a sticker you stick in, every PR a foil. It refuses the category's grey set table of input cells and checkmarks.

OWN-WORLD: Panini World Cup album grammar on the app's navy. Navy page ground #0A1224, royal #294DB8 header bands like team bands, empty slots drawn as thin outlines with last time's number printed inside, logged sets as white paper stickers (#F5F7FC, navy ink, 6px corners), PRs as royal foil stickers with a white border and one flat diagonal light-blue sheen band. Archivo: condensed black numerals for stickers, regular widths for UI text.

STORY: The lifter sees which workout is next, starts it in one tap, sticks sets without typing when the weight is the same, sees a foil the instant a PR lands, and finishes with a page of today's stickers worth sharing.

FIRST VIEWPORT: Workout screen. Material top app bar (back, Pull B, timer, A/B segmented button). Done exercises collapsed to one line each. The current exercise is the album row: royal band with its name, then slots at 56×64: white stickers for logged sets, foil for a PR, the printed slot with last time's number, a dashed slot for a new weight. Up next below. Bottom action bar in thumb reach: Add exercise, Finish.

FORM: Sticker album, position 6 of 7 on my ordered list; seed:47670694813b8704.

Signature interaction: a logged sticker lands tilted −3° and settles to 0° over 180 ms with a press; a PR sticker gets the foil sheen. Motion grammar: Material standard easing; everything else uses fade-through and container transform.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
