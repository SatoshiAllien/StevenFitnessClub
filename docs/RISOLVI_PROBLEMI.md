# L'app non va — Risoluzione problemi

## Fix applicati (giugno 2026)

- Scheme Xcode completato (mancava LaunchAction → il pulsante ▶ non funzionava)
- Rimosso `YOUR_TEAM_ID` invalido
- Corretto API HealthKit incompatibile
- Aggiunto alert se HealthKit non autorizzato

**Sincronizza iCloud sul Mac** prima di riaprire Xcode (icona nuvola completata).

---

## Checklist rapida sul Mac

### 1. Build fallisce (errore rosso in Xcode)

**Signing**
1. Progetto → Target StevenFitnessClub → **Signing & Capabilities**
2. ✅ **Automatically manage signing**
3. **Team** → seleziona il tuo Apple ID
4. Se errore bundle ID: cambia in `com.TUOAPPLEID.stevenfitnessclub`

**HealthKit**
1. Stessa tab → **+ Capability** → **HealthKit**
2. Se manca, aggiungilo manualmente

**Pulisci build**
```
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
```

### 2. Build ok ma app non si apre su iPhone

1. iPhone sbloccato, cavo USB collegato
2. **Impostazioni → Generali → VPN e gestione dispositivo** → Fidati del developer
3. In Xcode seleziona il **tuo iPhone** (non Simulator) in alto

### 3. App si apre ma è vuota

1. All'avvio tocca **Consenti** per Apple Salute
2. Su iPhone: **Impostazioni → Salute → Accesso dati e dispositivi → StevenFitnessClub** → attiva tutto
3. Nell'app Dashboard → icona **↻** in alto a destra per sincronizzare

### 4. Simulatore iPhone

Funziona solo per vedere l'interfaccia. **Nessun dato fitness reale** sul simulatore.

### 5. Progetto da iCloud

Copia locale consigliata (evita errori sync):
```bash
cp -R ~/Library/Mobile\ Documents/com~apple~CloudDocs/StevenFitnessClub ~/Desktop/StevenFitnessClub
cd ~/Desktop/StevenFitnessClub/ios
open StevenFitnessClub.xcodeproj
```

---

## Errori comuni

| Errore | Soluzione |
|--------|-----------|
| `Signing for StevenFitnessClub requires a development team` | Imposta Team in Signing |
| `No profiles for com.stevenfitnessclub.app` | Cambia Bundle ID o attiva automatic signing |
| `HealthKit entitlement missing` | Aggiungi capability HealthKit |
| `Failed to prepare device` | Fidati del computer su iPhone |
| Schermo nero | Autorizza HealthKit |

---

## Se ancora non funziona

In Xcode, copia il **primo errore rosso** da:
- **View → Navigators → Report** (ultima build)
- oppure il messaggio nel pannello in basso

E invialo per assistenza mirata.