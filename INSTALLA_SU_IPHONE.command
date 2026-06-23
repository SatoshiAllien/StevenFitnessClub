#!/bin/bash
# Doppio clic su questo file sul Mac per aprire il progetto in Xcode

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODEPROJ="$PROJECT_DIR/app/StevenFitnessClub.xcodeproj"
GITHUB="https://github.com/SatoshiAllien/StevenFitnessClub"

if [ ! -d "$XCODEPROJ" ]; then
  osascript -e "display alert \"Progetto non trovato\" message \"Non trovo StevenFitnessClub.xcodeproj.\n\nScarica da GitHub:\n$GITHUB\n\nPoi esegui:\ngit clone $GITHUB.git\ncd StevenFitnessClub\n./INSTALLA_SU_IPHONE.command\""
  exit 1
fi

open "$XCODEPROJ"

osascript <<'APPLESCRIPT'
display dialog "StevenFitnessClub — Installa su iPhone

1. In Xcode: clicca progetto BLU a sinistra
2. Tab Signing & Capabilities
3. ✅ Automatically manage signing
4. Team → il tuo Apple ID
5. + Capability → HealthKit (se manca)
6. In alto seleziona il TUO iPhone (non Simulator)
7. Collega iPhone con USB, sbloccalo
8. Premi ▶ (o ⌘R)

Al primo avvio su iPhone:
• Impostazioni → Generali → Gestione dispositivo → Fidati
• Consenti accesso Apple Salute nell'app
• Dashboard → icona ↻ per sincronizzare" buttons {"OK"} default button "OK" with title "StevenFitnessClub"
APPLESCRIPT