# StevenFitnessClub

App iOS avanzata di analisi fitness — stile Strava/TrainingPeaks, completamente offline su dati Apple Salute.

**Repository GitHub:** https://github.com/SatoshiAllien/StevenFitnessClub  
**Sito web:** https://satoshiallien.github.io/StevenFitnessClub/

---

## MacBook + Xcode (inizio rapido)

```bash
git clone https://github.com/SatoshiAllien/StevenFitnessClub.git
cd StevenFitnessClub
open app/StevenFitnessClub.xcodeproj
```

Oppure doppio clic su `INSTALLA_SU_IPHONE.command`.

In Xcode:
1. **Signing & Capabilities** → Team → tuo Apple ID
2. **+ Capability** → HealthKit
3. Seleziona il tuo **iPhone** (non Simulator)
4. Premi **▶** (⌘R)

Vedi [MACBOOK.txt](MACBOOK.txt) e [docs/AVVIO_MAC.md](docs/AVVIO_MAC.md) per la guida completa.

---

## Struttura repository

```
StevenFitnessClub/
├── app/                         ← Progetto Xcode (apri questo)
│   ├── StevenFitnessClub.xcodeproj
│   └── StevenFitnessClub/       ← Codice Swift
├── website/                     ← Sito vetrina
├── docs/                        ← Documentazione tecnica
└── INSTALLA_SU_IPHONE.command   ← Script avvio rapido Mac
```

---

## Funzionalità

- **Importazione HealthKit** — corsa, bici, nuoto, camminata (indoor/outdoor)
- **Dashboard** — riepilogo giornaliero/settimanale/mensile/annuale
- **Swift Charts** — distanza, ritmo, watt, FC, calorie, heatmap
- **Analisi avanzate** — zone cardio, VO₂ stimato, training load, stress score
- **Confronti** — attività vs attività, periodo vs periodo
- **AI Insights** — miglioramenti, debolezze, suggerimenti, previsioni
- **Export** — CSV, JSON, PDF

## Requisiti

- iOS 17.0+ · Xcode 15+ · iPhone con Apple Salute
- Apple Watch (opzionale, per FC/watt più ricchi)

## Documentazione

- [docs/TECHNICAL.md](docs/TECHNICAL.md) — architettura e modelli dati
- [docs/RISOLVI_PROBLEMI.md](docs/RISOLVI_PROBLEMI.md) — troubleshooting build