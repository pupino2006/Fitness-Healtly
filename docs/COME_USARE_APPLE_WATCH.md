# Come collegare e usare l’Apple Watch con LR Training Pro

## Cosa serve (obbligatorio)

| Pezzo | Perché |
|--------|--------|
| **Xcode** installato sul Mac | Compila l’app iPhone + Watch |
| **iPhone fisico** | Il Watch non si collega a un simulatore “vero” per HealthKit |
| **Apple Watch** accoppiato all’iPhone | App companion + FC/kcal |
| **Stesso Apple ID / Team** in Xcode | Firma l’app |

> Senza Xcode **non** si installa l’app nativa sul telefono, quindi il Watch **non** può ricevere la sessione.  
> Da Safari/PWA l’allenamento stile Fitness funziona già, ma **senza** calorie/FC reali dal Watch.

---

## 1) Build e installazione (una tantum)

Sul Mac, nella cartella del progetto:

```bash
cd /Users/lucaripa/Documents/GitHub/Fitness-Healtly
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer   # dopo aver installato Xcode
npm install
npm run build:www
npx cap sync ios
open ios/App/App.xcworkspace
```

In **Xcode**:

1. Seleziona il target **App** (iPhone).
2. **Signing & Capabilities** → il tuo Team → spunta “Automatically manage signing”.
3. Aggiungi capability **HealthKit**.
4. In Info aggiungi (se mancano):
   - *Privacy - Health Share Usage Description*
   - *Privacy - Health Update Usage Description*
5. Collega iPhone via cavo → sbloccalo → “Fidati di questo computer”.
6. In alto scegli il tuo **iPhone** come destinazione → **▶ Run**.

### Aggiungere l’app Watch (prima volta)

1. File → New → Target → **watchOS App** → nome `FitnessHealthyWatch`.
2. Embed in: **App**.
3. Sostituisci i file generati con quelli in `native/FitnessHealthyWatch/`.
4. Sul target Watch: capability **HealthKit** + stesse privacy keys.
5. Run di nuovo sul **iPhone** (l’app Watch si installa in automatico sul Watch accoppiato).

---

## 2) Collegare il Watch

1. Su iPhone: apri **Watch** → verifica che il Watch sia connesso (pallino verde / “Connesso”).
2. Sul Watch deve comparire **LR Training Pro** / FitnessHealthyWatch nella griglia app.
3. Apri l’app sul Watch **una volta** e accetta i permessi **Salute / Workout**.
4. Su iPhone, alla prima apertura, accetta **Salute** (FC, calorie, allenamenti).

Se il Watch non vede l’app:

- iPhone e Watch sulla stessa rete / Bluetooth on  
- Ripeti Run da Xcode sull’iPhone  
- Watch → App → cerca l’app e aprila a mano  

---

## 3) Come si usa (flusso)

### Dall’iPhone (consigliato)

1. Apri **LR Training Pro** sull’iPhone.
2. **Workout → Inizia workout → scegli scheda**.
3. Parte:
   - timer durata  
   - kcal attive / totali  
   - sessione inviata al Watch  
4. Sul **Watch** vedi l’esercizio corrente:
   - **Serie fatta** → completa la serie anche sull’iPhone  
   - **Recupero 90s** → timer + vibrazione  
   - frecce → esercizio successivo/precedente  
   - **Termina** → chiede di salvare sull’iPhone  
5. Oppure sull’iPhone: **Termina** → riepilogo → **Salva**.

### Controlli iPhone durante la sessione

- **Pausa / Riprendi**  
- **Termina** (salva)  
- **Annulla** (non salva)  
- **Completa serie** → avanza step-by-step nella scheda  

---

## 4) Cosa legge dal Watch

| Dato | Come |
|------|------|
| Frequenza cardiaca | HealthKit live sul Watch durante il workout |
| Kcal attive | `HKWorkoutSession` / energia attiva |
| Kcal totali | attive + stima basale sulla durata |
| Durata | timer sessione |

Finché usi solo browser (senza app nativa), le kcal sono **stimate** dal peso corporeo, non dal Watch.

---

## 5) Checklist se “non si collega”

1. Xcode ha installato l’app sull’**iPhone reale** (non Simulator).  
2. App Watch installata e aperta almeno una volta.  
3. Permessi Salute concessi su iPhone **e** Watch.  
4. Durante un workout, sullo status / log: Watch “raggiungibile” (Bluetooth ok).  
5. Hai fatto `npm run build:www && npx cap sync ios` dopo modifiche al codice web.

---

## Oggi su questo Mac

Stato attuale del repo:

- ✅ progetto `ios/` generato  
- ✅ CocoaPods ok (`FitnessWorkoutBridge` incluso)  
- ❌ **Xcode.app assente** → non si può ancora fare Run su device/Watch  

Prossimo passo tuo: installare **Xcode** (App Store o developer.apple.com), poi i comandi della sezione 1.
