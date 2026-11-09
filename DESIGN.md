---
name: Formazilla
description: Offline gym logger for Android where every set is a sticker on a navy album page.
colors:
  page: "#0A1224"
  card: "#141E36"
  chip: "#1E2A46"
  outline: "#5B6A8F"
  paper: "#F5F7FC"
  muted: "#949FBD"
  navy: "#294DB8"
  sheen: "#8CB0FF"
  on-band: "#DCE6FF"
  danger: "#E5675F"
  danger-outline: "#B0504F"
  scrim: "#050914"
typography:
  sticker-number:
    fontFamily: "Archivo, Roboto, sans-serif"
    fontSize: "24px"
    fontWeight: 800
    lineHeight: 1
    fontFeature: "'tnum' 1"
    fontVariation: "'wdth' 82"
  headline:
    fontFamily: "Archivo, Roboto, sans-serif"
    fontSize: "34px"
    fontWeight: 800
    lineHeight: 1.05
    fontVariation: "'wdth' 88"
  band-title:
    fontFamily: "Archivo, Roboto, sans-serif"
    fontSize: "20px"
    fontWeight: 800
    lineHeight: 1.1
    fontVariation: "'wdth' 85"
  title:
    fontFamily: "Archivo, Roboto, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.1
  body:
    fontFamily: "Archivo, Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.4
  label:
    fontFamily: "Archivo, Roboto, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.4
rounded:
  sticker: "6px"
  chip: "8px"
  card: "16px"
  key: "16px"
  sheet: "28px"
  pill: "28px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
components:
  button-primary:
    backgroundColor: "{colors.navy}"
    textColor: "{colors.paper}"
    rounded: "{rounded.pill}"
    height: "56px"
    padding: "0 20px"
  button-tonal:
    backgroundColor: "{colors.chip}"
    textColor: "{colors.paper}"
    rounded: "{rounded.pill}"
    height: "56px"
    padding: "0 20px"
  button-outlined:
    textColor: "{colors.sheen}"
    rounded: "{rounded.pill}"
    height: "48px"
    padding: "0 16px"
  button-danger:
    textColor: "{colors.danger}"
    rounded: "{rounded.pill}"
    height: "56px"
    padding: "0 20px"
  sticker:
    backgroundColor: "{colors.card}"
    borderColor: "{colors.sheen}"
    borderWidth: "2px"
    textColor: "{colors.paper}"
    typography: "{typography.sticker-number}"
    rounded: "{rounded.sticker}"
    size: "58px 64px"
  sticker-foil:
    backgroundColor: "{colors.navy}"
    textColor: "{colors.paper}"
    typography: "{typography.sticker-number}"
    rounded: "{rounded.sticker}"
    size: "58px 64px"
  slot-printed:
    textColor: "{colors.muted}"
    typography: "{typography.sticker-number}"
    rounded: "{rounded.sticker}"
    size: "58px 64px"
  album-band:
    backgroundColor: "{colors.navy}"
    textColor: "{colors.paper}"
    typography: "{typography.band-title}"
    padding: "12px 16px"
  nav-bar:
    backgroundColor: "{colors.card}"
    textColor: "{colors.muted}"
    height: "80px"
  nav-indicator:
    backgroundColor: "{colors.navy}"
    textColor: "{colors.paper}"
    rounded: "16px"
    size: "64px 32px"
  search-field:
    backgroundColor: "{colors.card}"
    textColor: "{colors.paper}"
    rounded: "{rounded.pill}"
    height: "56px"
    padding: "0 16px"
---

# Design System: Formazilla

## Overview

**Creative North Star: "The Sticker Album"**

Every workout is a page in a football sticker album. Each logged set is a dark sticker with a light-blue edge stuck into its slot; each personal record is a foil. The empty slot shows last time's number printed inside it, the way album slots print the player you're still missing, so repeating a weight is tap and Save. Panini albums are a shared ritual for Egyptian football fans, and the album grammar gives the app its own face without dressing it up as anything but a fast logging tool.

The album world lives only in the numbers: stickers, foils, printed slots and the navy header band over the current exercise. Everything around them is plain Material 3 on the app's original navy: top app bars, a four-tab navigation bar, bottom sheets, snackbars, segmented buttons. Density is medium, targets are big for sweaty thumbs, and the main action always sits at the bottom of the screen.

Ease of use outranks looks. The user rejected looks that feel like a generic AI app, and anything that costs extra taps or hides an action behind a gesture.

**Key Characteristics:**
- Navy page, dark stickers with a light-blue edge, navy foils with one light-blue sheen band.
- Condensed heavy Archivo numerals, tabular, as the loudest thing on every screen.
- One navy header band per page marks the current exercise or the page's subject.
- 56 px main buttons in a bottom bar; nothing tappable under 48 px.
- Every action is a labelled button or a visible handle; no secret gestures.

## Colors

The original navy palette, unchanged. Logged sets are Card Navy stickers with a Foil Sheen edge (no white faces: they glared in the gym).

### Primary
- **Album Navy** (#294DB8): header bands, foil stickers, the main button, the selected day, rotation and tab. One navy band per screen.
- **Foil Sheen** (#8CB0FF): the diagonal sheen band on foils (35% opacity), links, icons in outlined buttons, focus rings, the newest bar in charts.

### Neutral
- **Night Page** (#0A1224): page ground, the scene is a basement gym under fluorescent light.
- **Card Navy** (#141E36): cards, sheets, bottom bars, the navigation bar.
- **Chip Navy** (#1E2A46): tonal buttons, keypad keys, letter badges, list dividers.
- **Slot Outline** (#5B6A8F): printed slot outlines, outlined buttons, segmented-button borders, field borders. At least 3:1 on every navy, so the printed slot stays visible under gym glare.
- **Sticker Paper** (#F5F7FC): main text on navy and sticker numerals.
- **Muted Ink** (#949FBD): supporting text, dates, last-time numbers (5:1 or better on every navy).
- **Band Ink** (#DCE6FF): secondary text on the navy band and foils.
- **Delete Red** (#E5675F) with its outline (#B0504F): destructive actions only.
- **Scrim** (#050914 at 75%): behind bottom sheets.

### Named Rules
**The Sticker Is Earned Rule.** The light-blue sticker edge appears only around a logged set, a logged cardio time, or an exercise's best in Progress. Letter and number badges use Chip Navy with Foil Sheen text. Nothing decorative gets a sticker edge.
**The Fresh Foil Rule.** Foil marks a PR from the latest workout (and the Recent PRs strip). Older bests are plain edged stickers, so today's wins stand out.
**The One Band Rule.** One navy header band per screen, over the thing being worked on now.

## Typography

**Display Font:** Archivo (variable width and weight, bundled in the app so it works offline)
**Body Font:** Archivo (with Roboto fallback)

**Character:** One family, two voices: condensed black numerals for stickers and headlines, regular width for everything you read.

### Hierarchy
- **Sticker number** (800, 82% width, 15–76 px, line-height 1, tabular): weights on stickers, foils, printed slots and the keypad preview.
- **Headline** (800, 88% width, 34 px, 1.05): the one sentence that says what's next ("Pull B is next").
- **Band title** (800, 85% width, 18–21 px): the exercise or page name inside the navy band.
- **Title** (700, 22 px): top app bar titles.
- **Body** (500–700, 15–16 px): list rows, buttons.
- **Label** (400–600, 13 px): hints, dates, supporting lines. Nothing smaller than 12 px.

### Named Rules
**The Numbers Shout Rule.** The weight is always the biggest, heaviest text in its area.

## Layout

Phone layout, edge to edge, 16 px side margins, 4/8/12/16/20 spacing steps. Screens stack: status-bar inset (24), top app bar (64), content, then a fixed bottom bar holding the main action (56 tall, 12 px padding) above the navigation bar on tab screens. The navigation bar is 80 px plus the gesture-bar inset (96 total); bottom bars and sheets without it keep 28 px below their buttons so nothing sits on the gesture handle. Lists are rows of 56–68 px with a 1 px divider in Chip Navy. Sheets rise from the bottom with a 28 px top radius over a scrim.

## Elevation & Depth

Flat, with tonal layering: Night Page < Card Navy < Chip Navy. No drop shadows. The only depth cue is the sticker tilt: a just-logged sticker or a hero foil sits rotated −2° to −4°, as if freshly stuck.

### Named Rules
**The Tilt Means New Rule.** Only the newest sticker or a PR foil is tilted. Everything else sits straight.

## Shapes

Stickers have small 6 px corners (5 px when small, 8–10 px when large); cards 16 px; keypad keys 16 px; sheets 28 px on top; all buttons are full pills. Printed slots are 1.5 px solid outlines; the new-weight slot and the empty keypad preview are dashed.

## Components

### Stickers (signature)
- **Logged set:** Card Navy face, 2 px Foil Sheen edge, Sticker Paper numeral, "set n" caption in Foil Sheen; 58×64 in the workout, 30–42 px in summaries (1.5 px edge). Numbers shrink to fit at large text sizes.
- **PR foil:** Album Navy face, 3 px Sticker Paper border, one diagonal Foil Sheen band at 35%, "PR" caption in Band Ink.
- **Printed slot:** outline only, last time's number in Muted Ink. Tapping it opens the keypad with that weight selected: Save logs it, or the first key replaces it.
- **New slot:** dashed outline with a plus. Opens a clean, empty keypad.
- **Drop set:** a slightly narrower sticker pressed against the set before it, joined by a dashed edge, captioned "drop" with a down arrow.
- **More sets:** slots wrap onto a second row; nothing scrolls sideways.
- **Cardio:** one wider sticker with the minutes and a "min" caption; no sets, no foil.
- **Motion:** a new sticker lands at −3° and settles flat in 180 ms with a light haptic; a PR lands as foil with a stronger haptic. With animations off, it appears flat.

### Suggestion slip (Ask your AI coach)
- A 2 px dashed Foil Sheen outline on the page (no fill), radius 16, at least 64 tall. A 40 px Album Navy tile with a white icon, a Body-bold title, one Label line, and a Foil Sheen chevron.
- On Home it sits under the session section (resume card, or the day/rotation/one-time block), never above it. It is the only dashed card on Home, so it reads as "optional, open me" and never competes with Start.
- The Ask sheet lists questions as radio rows (48 tall), "See exactly what will be sent" as a text button, then Paste AI reply (outlined) and Share to my AI (primary) side by side.
- The reply screen shows the answer on a card, the plan preview on a card with a Foil Sheen edge, and AI weights as outlined pills ("AI suggests 40 · 45"), never as stickers.

### Album band
- Album Navy strip, 12×16 padding, band title left, a short status right ("3 of 6", a date) in Band Ink.

### Buttons
- **Shape:** full pill.
- **Primary:** Album Navy, white text, 56 tall, one per screen, in the bottom bar.
- **Tonal:** Chip Navy, Sticker Paper text, 56 tall, beside the primary.
- **Outlined:** 1 px Slot Outline, Foil Sheen text, 48 tall, for in-card options (Drop set, Superset, Edit).
- **Danger:** Delete Red text on a #6B3440 outline.
- **Empty state:** when there is nothing to save, the button says what's missing ("Type a weight to save") in Muted Ink on Chip Navy.

### Keypad
- Bottom sheet. Opened from +, it starts empty: dashed preview with a cursor and "type the weight", last time shown as a hint only, Save reads "Type a weight to save" until a number is typed. Keys 64 tall on Chip Navy.
- Opened from a logged sticker, it shows that set's weight on an edged sticker, already selected (Album Navy highlight), so typing replaces it without erasing. It adds −5/−2.5/+2.5/+5 nudges, Drop set, Delete set and "Save 30".

### Empty states
- The mascot plus one plain sentence about what will appear, and one tonal button to the next useful place. No foil or edged stickers until something is logged; History uses the mascot, Progress uses three empty printed slots.

### Segmented buttons and pickers
- Day picker: three 72 px tiles; selected tile is Album Navy with "Suggested" in Band Ink. Rotation and share pickers: outlined pill segments, the selected one filled navy with a check.

### Navigation
- Material 3 navigation bar, 80 px, Card Navy. Active tab: 64×32 Album Navy indicator behind a white icon, bold Sticker Paper label. Four tabs, always: Home, History, Progress, Templates.

### Lists
- Rows 56–68 px, title 16/600–700, supporting line 13 Muted Ink, trailing small sticker/foil, icon button or chevron. Reorder handles and remove buttons are always visible.

## Do's and Don'ts

### Do:
- **Do** put the screen's main action in the bottom bar at 56 px.
- **Do** open the keypad with the printed weight selected from the slot, and a clean keypad from +.
- **Do** show every action as a labelled button or visible handle (drop set, superset, edit, reorder, remove).
- **Do** use foils only for real PRs, and tilt only the newest sticker.
- **Do** keep data untouched in any redesign: same models, same `formazilla.json`, same signing key.

### Don't:
- **Don't** prefill the keypad from +; the user has to erase before typing.
- **Don't** hide actions behind long-press or swipe alone.
- **Don't** put stickers on menus, tabs or sheets; the album lives only in sets and PRs.
- **Don't** add drop shadows, gradients or glow; depth is tonal plus the sticker tilt.
- **Don't** add tabs or change their order.
