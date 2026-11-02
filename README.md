# Formazilla

A fast, offline gym logger for Push / Pull / Legs with A/B rotas.

- **One tap per set**: last time's weights show as dashed chips — tap to log. `+` repeats your last set.
- **Automatic PRs**: chips turn navy and a "New PR" badge appears the moment you beat your best.
- **Smart, not strict**: Home suggests the next day and rota from your history; switch with one tap.
- **Your numbers, as typed**: no kg/lb, no per-side math. Just the number you track.
- **Fully offline**: data stays on your phone. Backup = copy/paste JSON from the History tab.

## Install on your phone

1. Open **Releases** in this repo → latest build → download `formazilla.apk`.
2. Open it. Allow "Install unknown apps" for your browser if asked.
3. New builds install over the old one and keep your data.

## Develop

```bash
flutter create . --project-name formazilla --org app.formazilla --platforms android   # once
flutter pub get
flutter test
flutter run
```

See `CLAUDE.md` for architecture and rules.
