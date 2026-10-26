# FitnessHealthyWatch (watchOS)

Sorgenti SwiftUI da aggiungere come **Watch App target** nel progetto Xcode generato da Capacitor.

## File

| File | Ruolo |
|------|--------|
| `FitnessHealthyWatchApp.swift` | Entry point |
| `ContentView.swift` | UI idle / serie / recupero |
| `Models.swift` | Session / exercise / sets |
| `WatchSessionBridge.swift` | WatchConnectivity ↔ iPhone |
| `WatchWorkoutHealth.swift` | HKWorkoutSession + FC + kcal |

## Come aggiungere in Xcode

1. Apri `ios/App/App.xcworkspace`
2. File → New → Target → watchOS App
3. Product Name: `FitnessHealthyWatch`
4. Elimina i file stub generati
5. Trascina questa cartella nel target Watch
6. Abilita **HealthKit** sul target Watch
7. Copia le privacy keys da `../Info.plist.healthkit-snippet.xml`

## Controlli Watch

- **Serie fatta** → `setComplete` all’iPhone
- **Recupero 90s** → timer locale + haptic
- **← / →** → cambia esercizio
- **Termina** → chiude HK + chiede salvataggio sull’iPhone
