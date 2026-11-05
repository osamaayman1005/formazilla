# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

- Primary user today: the builder himself, an Egyptian lifter training Push / Pull / Legs with A/B rotations, who replaced a Google Sheet (push / pull / legs / PRs tabs) with this app.
- Later: a public release for Egyptian gym-goers (confirmed intent, no date). Design for that audience now: lifters in neighbourhood gyms and chains, phone in one hand between sets, often in basements with weak signal.
- The job: log every set in the seconds between sets without breaking focus, know which workout is next, and see the moment a personal record is beaten.

## Product Purpose

A fast, fully offline gym weight logger. Success: logging a set is quicker than typing it in a spreadsheet, nothing is lost, and PRs appear automatically.

## Positioning

One-tap set logging seeded from last time, automatic PRs, and a next-workout suggestion that never forces the plan. Weights are the numbers on the machine, stored exactly as typed: no units, no per-side math.

## Operating Context

- Used mid-workout, one-handed, between sets; sweaty hands; short rest windows.
- Plans come as splits of ordered days; each day has one or more rotations (A, B, …) that alternate.
- Plans are shared with gym friends as WhatsApp text, image cards, or QR codes scanned phone-to-phone.
- PRs are shared as story-size image cards.

## Capabilities and Constraints

- Fully offline; data stays on the phone. Backup is copy/paste text from History.
- Splits (presets: Push Pull Legs, Upper / Lower, Full body, Bro split, Arnold, custom), days, rotations; one-time workouts outside the plan (count for PRs and History only).
- Session: sets per exercise, drop sets, supersets, cardio logged as minutes (no PRs), rename, reorder, add/remove; edits inside a plan workout update its template.
- Progress per exercise: all-time PR, gain since start, top weight per session, history.
- Templates: switch split, edit days, add/duplicate/rename/delete rotations, share and import plans.
- Language: English only. No Arabic or RTL planned for now.
- Flutter app shipped as a signed APK from CI; no store listing yet.
- No new features in the current redesign: it changes look and usability only.
- The redesign must never erase data: no change to the data models, the `formazilla.json` file or its schema (v4), or the APK signing key. A new build installs over the old one and keeps every workout, PR and plan. Any future schema change needs a tested migration from the previous version.
- Set logging: tapping the outlined "last time" slot logs that weight in one tap with no keypad. Tapping + opens a clean, empty keypad (no prefilled weight) so a new number is typed without erasing anything. Tapping a logged sticker opens the keypad with that set's weight, to edit or delete it.

## Brand Commitments

- Name: Formazilla.
- Navy colours stay (confirmed). Current tokens live in `lib/core/theme.dart`.
- The dino logo and the dino-lifting-a-barbell mascot stay (`assets/logo.png`, `assets/mascot.png`).
- Four tabs stay: Home, History, Progress, Templates.
- Ease of use is the first priority, above looks.
- Must not look like a generic AI-made app.

## Evidence on Hand

- Logo and mascot: `assets/logo.png`, `assets/mascot.png`, `docs/logo.png`.
- Starter plans and exercise library: `lib/data/seed.dart`.
- No users, testimonials, ratings, or download numbers exist; do not invent any.

## Product Principles

1. Fewest taps wins: anything slower than a rest period doesn't get logged.
2. Nothing hidden: every action mid-workout is a visible, labelled control, not a secret gesture.
3. Suggest, never enforce: any day or rotation is one tap away.
4. The numbers are the product: the user's own weights, exactly as typed.
5. Offline and safe: data never needs a connection and is never silently lost.
