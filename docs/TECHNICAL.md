# StevenFitnessClub — Documentazione Tecnica

## Architettura

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│  Dashboard │ Activities │ Insights │ Compare │ Export│
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│              AnalyticsEngine + InsightsEngine        │
│  Trend │ Regressioni │ Zone cardio │ Previsioni     │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│              WorkoutDataStore (cache locale)         │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│              HealthKitService                          │
│  Workout │ HR │ Power │ Steps │ VO₂ │ Background sync │
└───────────────────────────────────────────────────────┘
```

L'app funziona **completamente offline** dopo la sincronizzazione iniziale. I dati sono cachati in `UserDefaults` (JSON encoded).

## HealthKit — Tipi letti

| Tipo HK | Utilizzo |
|---------|----------|
| `HKWorkout` | Attività principale |
| `distanceWalkingRunning` | Distanza corsa/camminata |
| `distanceCycling` | Distanza bici |
| `distanceSwimming` | Distanza nuoto |
| `activeEnergyBurned` | Calorie attive |
| `stepCount` | Passi |
| `heartRate` | FC media/max/min + zone |
| `vo2Max` | VO₂ max |
| `runningPower` / `cyclingPower` | Watt |
| `cyclingCadence` | Cadenza bici |
| `runningSpeed` | Velocità/ritmo |
| `flightsClimbed` | Elevazione |

### Background Delivery

Abilitato per: `heartRate`, `activeEnergyBurned`, `stepCount`, `distanceWalkingRunning`, `workoutType` con frequenza `hourly`/`immediate`.

## Modelli di analisi

### Zone cardio (5 zone)

| Zona | % FC max | Nome |
|------|----------|------|
| Z1 | < 60% | Recupero |
| Z2 | 60-70% | Aerobico |
| Z3 | 70-80% | Tempo |
| Z4 | 80-90% | Soglia |
| Z5 | > 90% | Massimale |

### Performance Score

```
score = min(100, distanza_settimanale_km × 2 + (100 - stress) × 0.3)
```

### Training Load

```
load = Σ (durata_ore × FC_media / 100) per ultimi 30 workout
```

### Regressione lineare (previsioni)

Usata per predire ritmo futuro e trend VO₂ basandosi sugli ultimi N workout dello stesso sport.

## Swift Charts

| Chart | Tipo | Dati |
|-------|------|------|
| `DistanceTrendChart` | Area + Line | km nel tempo |
| `PaceTrendChart` | Line + Point | ritmo min/km |
| `PowerTrendChart` | Bar | watt |
| `HeartRateTrendChart` | Line gradient | bpm |
| `CaloriesBarChart` | Bar | kcal |
| `HeartRateZonePieChart` | Sector (donut) | zone cardio |
| `WeeklyHeatmapChart` | Grid colorata | km/giorno |
| `SplitPaceChart` | Bar | ritmo per km |

## AI Insights (offline)

Il motore `InsightsEngine` genera insight basati su regole e trend locali:

- **Improvement** — volume in crescita, trend positivo
- **Weakness** — squilibrio zone cardio (troppo Z4-Z5 o troppo Z1-Z2)
- **Training** — suggerimenti frequenza e intensità
- **Prediction** — previsione ritmo/VO₂ da regressione
- **Recovery** — stress score elevato, volume in calo

Nessuna chiamata cloud: tutto calcolato on-device.

## Export

| Formato | Contenuto |
|---------|-----------|
| **CSV** | Una riga per workout con tutte le metriche |
| **JSON** | Workout + performance metrics + insights |
| **PDF** | Report formattato con score, lista workout, insights |

## Sport supportati

| Sport | Metriche specifiche |
|-------|---------------------|
| Corsa outdoor | Ritmo/km, elevazione, zone, watt stimati |
| Corsa indoor | Ritmo treadmill, FC, zone |
| Camminata | Passi, distanza, calorie, FC |
| Bici outdoor | Watt, velocità, elevazione, zone |
| Bici indoor | Watt, cadenza, FC |
| Nuoto | Stile, vasche, ritmo/100m, FC |

## Setup Xcode

1. Bundle ID: `com.stevenfitnessclub.app`
2. Deployment Target: iOS 17.0
3. Capabilities: HealthKit + Background Delivery
4. Frameworks: HealthKit, Charts (built-in iOS 16+), PDFKit

## Privacy

- Nessun tracking
- Nessun server/cloud
- Dati fitness non collegati all'identità
- Privacy Manifest incluso (`PrivacyInfo.xcprivacy`)