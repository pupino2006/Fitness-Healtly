# LR Training Pro — iOS + Apple Watch + HealthKit

Questa guida collega l’app web esistente a una build nativa Capacitor con:

- **HealthKit** (calorie, FC, workout strength)
- **Apple Watch companion** (serie, recupero, termina sessione)
- Sync bidirezionale via **WatchConnectivity**

## Prerequisiti

1. **Xcode ufficiale** (obbligatorio per HealthKit/Watch nativi):
   - **App Store** → cerca “Xcode”, oppure
   - [Apple Developer Downloads](https://developer.apple.com/download/all/) con Apple ID (versioni precedenti se il Mac non supporta l’ultima)
   - **Non** usare Xcode da siti terzi / torrent / “crack”: non è supportato, rischioso, e non posso aiutarti a scaricarlo da lì.
2. Se non vuoi aggiornare il Mac: prendi da developer.apple.com una **versione Xcode compatibile** col tuo macOS, oppure usa un Mac in cloud (MacStadium, GitHub Actions `macos-latest`) solo per firmare/buildare.
3. Dopo l’installazione:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   brew install cocoapods
   ```
4. Account Apple Developer + iPhone/Watch reali (il simulatore non dà FC vera)

**Nota:** l’app web ha già un flusso stile Fitness (timer, pausa, kcal stimate, step esercizi). Le kcal “vere” da Watch arrivano solo con la build nativa HealthKit.

## Setup rapido

```bash
cd /Users/lucaripa/Documents/GitHub/Fitness-Healtly
npm install
npm run build:www
npx cap add ios          # solo la prima volta
npm run ios              # sync + apre Xcode
```

## Xcode — capabilities obbligatorie

Apri `ios/App/App.xcworkspace`.

### Target iPhone (`App`)

1. **Signing & Capabilities**
   - Team personale / Developer
   - Bundle ID: `com.lucaripa.fitnesshealtly`
2. Aggiungi capability:
   - **HealthKit**
   - **Background Modes** → Audio / acts as Bluetooth LE / Health updates (opzionale)
3. In `Info.plist` (o Custom iOS Target Properties):
   - `NSHealthShareUsageDescription` = `Serve per salvare allenamenti, frequenza cardiaca e calorie.`
   - `NSHealthUpdateUsageDescription` = `Serve per scrivere la sessione di allenamento in Salute.`
4. Registra il plugin nativo (se non auto-linkato via SPM/CocoaPods):
   - Assicurati che `FitnessWorkoutBridge` sia nel Podfile / package dependencies
   - File Swift: `plugins/workout-bridge/ios/Sources/WorkoutBridgePlugin/WorkoutBridgePlugin.swift`

### Target Apple Watch

1. File → New → Target → **watchOS → App**
2. Nome: `FitnessHealthyWatch`
3. Embed in: App iPhone
4. Sostituisci i file generati con quelli in:
   ```
   native/FitnessHealthyWatch/
     FitnessHealthyWatchApp.swift
     ContentView.swift
     Models.swift
     WatchSessionBridge.swift
     WatchWorkoutHealth.swift
   ```
5. Capabilities Watch target:
   - **HealthKit**
   - stesso Team / App Group opzionale
6. Stesse privacy keys HealthKit nel Watch `Info.plist`

### WatchConnectivity

Non serve capability dedicata: basta WCSession su iPhone + Watch con stesso Team e app companion.

## Flusso utente

1. Su iPhone: **Workout → Inizia → scegli scheda**
2. Parte sessione HealthKit + sync sul Watch
3. Sul Watch vedi esercizio corrente:
   - **Serie fatta** → completa set anche sull’iPhone
   - **Recupero 90s** → timer + haptic
   - frecce per cambiare esercizio
   - **Termina** → chiude sessione e salva
4. In chiusura: kcal + FC medie salvate nello storico sessione

## Test

| Dove | Cosa verificare |
|------|-----------------|
| Safari / browser | App web normale, bridge no-op |
| iPhone device | Permessi Salute, barra FC/kcal in workout |
| Watch | UI serie, recupero, sync |

## Note importanti

- La FC accurata e le calorie “vere” arrivano soprattutto se il **workout HealthKit gira sul Watch** (`WatchWorkoutHealth`).
- Su **simulatore** HealthKit è limitato: usa device reali.
- Se `xcodebuild` dice che manca Xcode: esegui `xcode-select` come sopra.
- Dopo ogni modifica a `index.html` / `js/`:
  ```bash
  npm run cap:sync
  ```

## Prossimi step possibili

- Avvio workout **direttamente dal Watch** (lista schede offline)
- Complication Watch (prossimo workout)
- Siri Shortcut “Inizia Spinte 1”
- Sync sessioni HealthKit → Supabase
