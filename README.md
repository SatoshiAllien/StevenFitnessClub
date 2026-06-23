# StevenFitnessClub

App iOS avanzata di analisi fitness — stile Strava/TrainingPeaks, completamente offline su dati Apple Salute.

## Funzionalità

- **Importazione HealthKit** — corsa, bici, nuoto, camminata (indoor/outdoor)
- **Dashboard** — riepilogo giornaliero/settimanale/mensile/annuale
- **Swift Charts** — distanza, ritmo, watt, FC, calorie, heatmap
- **Analisi avanzate** — zone cardio, VO₂ stimato, training load, stress score
- **Confronti** — attività vs attività, periodo vs periodo
- **AI Insights** — miglioramenti, debolezze, suggerimenti, previsioni
- **Export** — CSV, JSON, PDF

## Design

| Elemento | Valore |
|----------|--------|
| Blu elettrico | `#007AFF` |
| Nero profondo | `#0A0A0A` |
| Verde performance | `#00FF7F` |
| Arancione energia | `#FF7A00` |

## Struttura

```
steven-fitness-club/ios/StevenFitnessClub/
├── Theme/           Design system
├── Models/          WorkoutActivity, AnalysisModels
├── Services/        HealthKitService, WorkoutDataStore
├── Analytics/       AnalyticsEngine, InsightsEngine
├── Export/          ExportService (CSV/JSON/PDF)
├── Views/           Dashboard, Activities, Charts, Compare, Insights, Export
└── Components/      MetricCard, PeriodPicker
```

## Avvio

1. Apri `ios/StevenFitnessClub.xcodeproj` in **Xcode 15+**
2. Imposta il tuo **Development Team**
3. Abilita capability **HealthKit**
4. Run su iPhone (HealthKit richiede dispositivo reale per dati completi)

## Requisiti

- iOS 17.0+
- Xcode 15+
- iPhone con Apple Salute configurato
- Apple Watch (opzionale, per dati FC/watt più ricchi)

## Documentazione

Vedi [docs/TECHNICAL.md](docs/TECHNICAL.md) per architettura, modelli dati e API HealthKit.