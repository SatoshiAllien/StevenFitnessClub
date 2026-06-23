# Avviare StevenFitnessClub sul Mac

## 1. Porta il progetto sul Mac

Se il codice è su Windows/WSL, copialo sul Mac con uno di questi metodi:

**Git (consigliato)**
```bash
# Sul Mac — scarica l'ultima versione
git clone https://github.com/SatoshiAllien/StevenFitnessClub.git
cd StevenFitnessClub
./INSTALLA_SU_IPHONE.command
```

**USB / AirDrop / cartella condivisa**
Copia l'intera cartella `steven-fitness-club` sul Mac.

## 2. Requisiti sul Mac

- macOS 14 Sonoma o superiore
- **Xcode 15+** — installa dall'App Store
- Apri Xcode una volta e accetta la licenza:
  ```bash
  sudo xcodebuild -license accept
  ```

## 3. Apri il progetto

```bash
cd StevenFitnessClub/app
open StevenFitnessClub.xcodeproj
```

Oppure: Xcode → **File → Open** → seleziona `StevenFitnessClub.xcodeproj`

## 4. Configura signing

1. Clicca sul progetto **StevenFitnessClub** (icona blu a sinistra)
2. Target **StevenFitnessClub** → tab **Signing & Capabilities**
3. **Team**: seleziona il tuo Apple ID (Account gratuito va bene per test sul tuo iPhone)
4. Verifica che **Bundle Identifier** sia `com.stevenfitnessclub.app`
5. Controlla che **HealthKit** sia nella lista capabilities

Se non hai un Team:
- Xcode → **Settings → Accounts** → **+** → aggiungi Apple ID

## 5. Scegli dove eseguire

| Destinazione | HealthKit | Consiglio |
|--------------|-----------|-----------|
| **iPhone fisico** (USB) | Dati reali | Migliore opzione |
| **Simulatore** (es. iPhone 15) | Dati limitati/fake | Solo per vedere l'UI |

Per iPhone fisico:
1. Collega iPhone con cavo USB
2. Sblocca il telefono → **Fidati di questo computer**
3. In Xcode, menu in alto: seleziona il tuo **iPhone** (non Simulator)

## 6. Run

Premi **⌘R** oppure il pulsante ▶ Play.

Al primo avvio su iPhone:
- Vai su **Impostazioni → Generali → Gestione VPN e dispositivo** → Fidati del developer
- L'app chiederà accesso ad **Apple Salute** → autorizza tutto

## 7. Problemi comuni

**"No signing certificate"**
→ Signing & Capabilities → spunta **Automatically manage signing** + seleziona Team

**Build failed — HealthKit**
→ Target → Signing & Capabilities → **+ Capability** → HealthKit

**Simulatore senza dati**
→ Normale. Usa un iPhone reale con workout registrati in Apple Salute / Apple Watch

**Progetto su percorso WSL/network**
→ Copia il progetto in `~/Developer/steven-fitness-club` sul Mac locale (iCloud/Desktop ok)

## 8. VS Code sul Mac (opzionale)

Puoi usare VS Code per editare e Xcode solo per compilare:

```bash
brew install --cask visual-studio-code
code ~/Developer/steven-fitness-club
```

Poi apri Xcode in parallelo per **⌘R**.