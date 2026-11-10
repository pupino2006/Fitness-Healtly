import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth

    var body: some View {
        Group {
            if let summary = bridge.summary {
                SummaryView(summary: summary)
            } else if bridge.countdownValue != nil {
                CountdownView()
            } else if bridge.isRecovering {
                RecoveryView()
            } else if let session = bridge.session, let ex = session.currentExercise {
                ActiveWorkoutPager(session: session, exercise: ex)
            } else {
                IdleView()
            }
        }
    }
}

// MARK: - Idle (lista schede stile Fitness)

struct IdleView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.green)
                    Text("Allenamento")
                        .font(.headline.weight(.bold))
                }

                ActivityRingsView(
                    move: health.todayMoveKcal / max(health.moveGoalKcal, 1),
                    exercise: health.todayExerciseMin / max(health.exerciseGoalMin, 1),
                    steps: health.todaySteps / max(health.stepsGoal, 1)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                HStack(spacing: 8) {
                    ringStat(title: "MUOVI", value: "\(Int(health.todayMoveKcal))", tint: .pink)
                    ringStat(title: "ALLENA", value: "\(Int(health.todayExerciseMin))m", tint: .green)
                    ringStat(title: "PASSI", value: formatSteps(health.todaySteps), tint: .cyan)
                }

                Label(
                    bridge.plansReady ? "Schede pronte" : "Sincronizza da iPhone",
                    systemImage: bridge.plansReady ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath"
                )
                .font(.caption2)
                .foregroundStyle(bridge.plansReady ? .green : .secondary)

                Label(
                    health.authOk ? "Salute attiva" : "Autorizza Salute",
                    systemImage: health.authOk ? "heart.fill" : "heart"
                )
                .font(.caption2)
                .foregroundStyle(health.authOk ? .pink : .secondary)
                .onTapGesture { health.requestAuth() }

                if !bridge.statusText.isEmpty {
                    Text(bridge.statusText)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                ForEach(bridge.groups, id: \.self) { group in
                    Button {
                        bridge.requestStartWorkout(group)
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.22))
                                    .frame(width: 34, height: 34)
                                Image(systemName: iconForGroup(group))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.green)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(group)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Text(subtitleForGroup(group))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.green.opacity(0.8))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.green.opacity(0.12))
                    )
                }
            }
            .padding(.horizontal, 2)
        }
        .onAppear { health.refreshTodayRings() }
    }

    private func ringStat(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption2.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityRingsView: View {
    let move: Double
    let exercise: Double
    let steps: Double

    var body: some View {
        ZStack {
            ring(progress: move, color: .pink, width: 8, inset: 0)
            ring(progress: exercise, color: .green, width: 8, inset: 11)
            ring(progress: steps, color: .cyan, width: 8, inset: 22)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.green)
        }
        .frame(width: 92, height: 92)
        .frame(maxWidth: .infinity)
    }

    private func ring(progress: Double, color: Color, width: CGFloat, inset: CGFloat) -> some View {
        let p = min(max(progress, 0), 1.05)
        return Circle()
            .stroke(color.opacity(0.2), lineWidth: width)
            .padding(inset)
            .overlay(
                Circle()
                    .trim(from: 0, to: p)
                    .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(inset)
            )
    }
}

func formatSteps(_ steps: Double) -> String {
    let n = Int(steps.rounded())
    if n >= 1000 {
        let k = Double(n) / 1000.0
        return String(format: k.rounded() == k ? "%.0fk" : "%.1fk", k)
    }
    return "\(n)"
}

// MARK: - Countdown 3-2-1-Via

struct CountdownView: View {
    @EnvironmentObject var bridge: WatchSessionBridge

    private var label: String {
        guard let v = bridge.countdownValue else { return "" }
        return v == 0 ? "Via" : "\(v)"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                Text(label)
                    .font(.system(size: bridge.countdownValue == 0 ? 44 : 64, weight: .black, design: .rounded))
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: bridge.countdownValue)
                Text(bridge.pendingGroupLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Button("Annulla") { bridge.cancelCountdown() }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - Pager allenamento (sinistra controlli / destra workout)

struct ActiveWorkoutPager: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    let session: WatchSession
    let exercise: WatchExercise
    @State private var page = 1

    var body: some View {
        TabView(selection: $page) {
            WorkoutControlsPage(session: session, exercise: exercise)
                .tag(0)
            ActiveWorkoutView(session: session, exercise: exercise)
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .sheet(isPresented: $bridge.showAddExercisePicker) {
            AddExerciseSheet()
        }
    }
}

struct WorkoutControlsPage: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth
    let session: WatchSession
    let exercise: WatchExercise

    private var paused: Bool { bridge.isPaused || health.isPaused }
    private var canCompleteSet: Bool {
        exercise.sets.contains(where: { !$0.done })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(session.gruppo.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    controlButton(
                        title: "Termina",
                        systemImage: "xmark",
                        tint: .red
                    ) {
                        bridge.finishSession()
                    }

                    controlButton(
                        title: paused ? "Riprendi" : "Pausa",
                        systemImage: paused ? "play.fill" : "pause.fill",
                        tint: .yellow
                    ) {
                        bridge.pauseOrResume()
                    }

                    controlButton(
                        title: "Nuovo",
                        systemImage: "plus",
                        tint: .blue
                    ) {
                        bridge.showAddExercisePicker = true
                    }

                    controlButton(
                        title: "Serie",
                        systemImage: "checkmark",
                        tint: .green,
                        disabled: !canCompleteSet || paused
                    ) {
                        bridge.completeCurrentSet()
                    }
                }

                if paused {
                    Text("In pausa")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.yellow)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func controlButton(
        title: String,
        systemImage: String,
        tint: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(disabled ? 0.15 : 0.25))
                        .frame(width: 44, height: 44)
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(disabled ? tint.opacity(0.35) : tint)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(disabled ? .secondary : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct AddExerciseSheet: View {
    @EnvironmentObject var bridge: WatchSessionBridge

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aggiungi")
                    .font(.headline)
                Button {
                    bridge.addExtraExercise()
                } label: {
                    Label("Esercizio extra", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                if let sess = bridge.session, !sess.exercises.isEmpty {
                    Text("Vai a")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(sess.exercises) { ex in
                        Button {
                            bridge.jumpToExercise(exId: ex.exId)
                        } label: {
                            Text(ex.name)
                                .font(.caption2)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button("Chiudi") { bridge.showAddExercisePicker = false }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Vista allenamento + dettagli in basso

struct ActiveWorkoutView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth
    let session: WatchSession
    let exercise: WatchExercise

    private var pendingSet: WatchExerciseSet? {
        exercise.sets.first(where: { !$0.done })
    }

    private var exerciseVolume: Double {
        computeVolumeKg([exercise])
    }

    private var paused: Bool { bridge.isPaused || health.isPaused }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconForGroup(session.gruppo))
                        .foregroundStyle(.green)
                    Text(session.gruppo.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                    Spacer()
                    Text("\(session.currentExerciseIndex + 1)/\(session.exercises.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if paused {
                    Label("In pausa", systemImage: "pause.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.yellow)
                }

                Text(exercise.name)
                    .font(.headline.weight(.bold))
                    .lineLimit(3)

                HStack(spacing: 10) {
                    if let hr = health.heartRate {
                        Label("\(Int(hr))", systemImage: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                    Label("\(Int(health.activeCalories))", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text(formatVolume(session.totalVolumeKg))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.yellow)
                }
                .font(.caption2)

                let done = exercise.sets.filter(\.done).count
                Text("Serie \(min(done + (pendingSet == nil ? 0 : 1), exercise.sets.count))/\(exercise.sets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let next = pendingSet {
                    partControls(exercise: exercise, set: next)

                    Button {
                        bridge.completeCurrentSet()
                    } label: {
                        Label("Chiudi serie", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(paused)
                } else if session.currentExerciseIndex < session.exercises.count - 1 {
                    Button {
                        bridge.nextExercise()
                    } label: {
                        Label("Prossimo esercizio", systemImage: "chevron.right.circle.fill")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button {
                        bridge.finishSession()
                    } label: {
                        Label("Termina allenamento", systemImage: "flag.checkered")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Button {
                    bridge.startRecovery(seconds: exercise.recSec ?? 90, label: exercise.name)
                } label: {
                    Label("Recupero \(exercise.recSec ?? 90)s", systemImage: "timer")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(paused)

                // Dettagli scorrendo in basso: volume esercizio + contesto sessione
                VStack(alignment: .leading, spacing: 8) {
                    Divider().padding(.vertical, 4)

                    Text("DETTAGLI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)

                    detailStat(title: "Volume esercizio", value: formatVolume(exerciseVolume), tint: .yellow)
                    detailStat(title: "Volume sessione", value: formatVolume(session.totalVolumeKg), tint: .orange)
                    detailStat(
                        title: "Serie fatte",
                        value: "\(exercise.sets.filter(\.done).count)/\(exercise.sets.count)",
                        tint: .green
                    )

                    Text("Serie")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    ForEach(exercise.sets) { set in
                        HStack {
                            Text("Serie \(set.setNumber)")
                                .font(.caption2)
                            Spacer()
                            Text(setDetailLine(set))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(set.done ? .primary : .secondary)
                            if set.done {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    if !session.upcomingExercises.isEmpty {
                        Text("Dopo")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                        ForEach(session.upcomingExercises.prefix(6)) { ex in
                            HStack(alignment: .top) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.green.opacity(0.8))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(ex.name)
                                        .font(.caption2.weight(.semibold))
                                        .lineLimit(2)
                                    Text("Vol. \(formatVolume(computeVolumeKg([ex])))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    HStack {
                        Button {
                            bridge.prevExercise()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.bordered)
                        .disabled(session.currentExerciseIndex == 0)

                        Button {
                            bridge.nextExercise()
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                        .disabled(session.currentExerciseIndex >= session.exercises.count - 1)

                        Spacer()

                        Button {
                            bridge.undoLastSet()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func detailStat(title: String, value: String, tint: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        }
    }

    private func setDetailLine(_ set: WatchExerciseSet) -> String {
        var parts = ["\(set.reps)×\(formatKg(set.peso))"]
        if let p2 = set.peso2 {
            parts.append("\(set.reps2 ?? set.reps)×\(formatKg(p2))")
        }
        if let p3 = set.peso3 {
            parts.append("\(set.reps3 ?? set.reps)×\(formatKg(p3))")
        }
        return parts.joined(separator: " + ") + " kg"
    }

    @ViewBuilder
    private func partControls(exercise: WatchExercise, set: WatchExerciseSet) -> some View {
        let names = exercise.partNames ?? []
        loadRow(title: names.first ?? "Kg", reps: set.reps, peso: set.peso, part: 1)
        if names.count > 1 {
            loadRow(title: names[1], reps: set.reps2 ?? set.reps, peso: set.peso2 ?? 0, part: 2)
        }
        if names.count > 2 {
            loadRow(title: names[2], reps: set.reps3 ?? set.reps, peso: set.peso3 ?? 0, part: 3)
        }
    }

    private func loadRow(title: String, reps: Int, peso: Double, part: Int) -> some View {
        let step: Double = peso >= 100 ? 5 : 2.5
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
            StepperRow(title: "Rep", value: "\(reps)") {
                bridge.adjustCurrent(repsDelta: -1, part: part)
            } plus: {
                bridge.adjustCurrent(repsDelta: 1, part: part)
            }
            StepperRow(title: "Kg", value: formatKg(peso)) {
                bridge.adjustCurrent(pesoDelta: -step, part: part)
            } plus: {
                bridge.adjustCurrent(pesoDelta: step, part: part)
            }
        }
        .disabled(paused)
        .opacity(paused ? 0.45 : 1)
    }
}

struct StepperRow: View {
    let title: String
    let value: String
    let minus: () -> Void
    let plus: () -> Void

    var body: some View {
        HStack {
            Button(action: minus) {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            Button(action: plus) {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Recovery / Summary

struct RecoveryView: View {
    @EnvironmentObject var bridge: WatchSessionBridge

    private var urgent: Bool { bridge.recoverySecondsLeft <= 5 }

    var body: some View {
        ZStack {
            (urgent ? Color.red : Color.green)
                .ignoresSafeArea()
            VStack(spacing: 6) {
                Text("RECUPERO")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(timeString(bridge.recoverySecondsLeft))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                if !bridge.recoveryNextLabel.isEmpty {
                    Text("PROSSIMO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 2)
                    Text(bridge.recoveryNextLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                Button("Salta") { bridge.stopRecovery() }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct SummaryView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    let summary: WatchSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Label("Completato", systemImage: "checkmark.seal.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
                Text(summary.gruppo)
                    .font(.headline)
                    .lineLimit(2)
                Text(timeString(summary.durationSec))
                    .font(.title3.weight(.black))
                    .monospacedDigit()
                Text(formatVolume(summary.totalVolumeKg))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.yellow)
                Text("kg sollevati")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack {
                    Label("\(Int(summary.activeCalories.rounded()))", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                    if let hr = summary.averageHeartRate {
                        Label("\(Int(hr.rounded()))", systemImage: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                }
                .font(.caption2)

                ForEach(summary.exercises) { ex in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(ex.name)
                                .font(.caption2.weight(.bold))
                                .lineLimit(2)
                            Spacer()
                            Text(formatVolume(computeVolumeKg([ex])))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.yellow)
                        }
                        ForEach(ex.sets) { set in
                            let extra = set.peso2 != nil ? " + \(set.reps2 ?? set.reps)×\(formatKg(set.peso2 ?? 0))" : ""
                            Text("\(set.setNumber)  \(set.reps)×\(formatKg(set.peso))\(extra) kg\(set.done ? "  ✓" : "")")
                                .font(.caption2)
                                .foregroundStyle(set.done ? .primary : .secondary)
                        }
                        if let rec = ex.recSec, rec > 0 {
                            Text("Recupero \(rec)s")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }

                Button("Chiudi") { bridge.dismissSummary() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Resoconto")
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
}

// MARK: - Helpers

func iconForGroup(_ group: String) -> String {
    let g = group.lowercased()
    if g.contains("gambe") { return "figure.strengthtraining.functional" }
    if g.contains("tirata") || g.contains("schiena") || g.contains("dorso") { return "figure.climbing" }
    if g.contains("spalle") || g.contains("petto") || g.contains("spinte") {
        return "figure.strengthtraining.traditional"
    }
    if g.contains("ss") { return "arrow.triangle.2.circlepath" }
    return "dumbbell.fill"
}

func subtitleForGroup(_ group: String) -> String {
    let g = group.lowercased()
    if g.contains("gambe") && g.contains("dorso") { return "Superserie · gambe/dorso" }
    if g.contains("petto") && g.contains("spalle") { return "Superserie · petto/spalle" }
    if g.contains("gambe") { return "Forza inferiore" }
    if g.contains("tirata") || g.contains("schiena") { return "Trazioni · dorso" }
    if g.contains("spinte") { return "Spinte · petto" }
    if g.contains("spalle") { return "Spalle · petto" }
    return "Forza"
}

func computeVolumeKg(_ exercises: [WatchExercise]) -> Double {
    exercises.reduce(0) { acc, ex in
        acc + ex.sets.reduce(0) { sum, set in
            // Per i dettagli mostriamo il volume programmato/eseguito: set done o tutti i kg previsti
            sum + set.liftedKg
        }
    }
}

func formatKg(_ value: Double) -> String {
    if abs(value.rounded() - value) < 0.05 {
        return String(format: "%.0f", value)
    }
    return String(format: "%.1f", value)
}

func formatVolume(_ kg: Double) -> String {
    let rounded = Int(kg.rounded())
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "it_IT")
    formatter.maximumFractionDigits = 0
    let text = formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
    return "\(text) kg"
}
