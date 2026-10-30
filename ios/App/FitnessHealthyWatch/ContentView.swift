import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth

    var body: some View {
        NavigationStack {
            if let summary = bridge.summary {
                SummaryView(summary: summary)
            } else if bridge.isRecovering {
                RecoveryView()
            } else if let session = bridge.session, let ex = session.currentExercise {
                ActiveWorkoutView(session: session, exercise: ex)
            } else {
                IdleView()
            }
        }
    }
}

struct IdleView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("LR Training")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Label(bridge.plansReady ? "Schede sul Watch" : "Copio le schede…", systemImage: bridge.plansReady ? "applewatch" : "arrow.down.circle")
                    .font(.caption2)
                    .foregroundStyle(bridge.plansReady ? .green : .secondary)

                Label(health.authOk ? "Salute OK" : "Autorizza Salute", systemImage: health.authOk ? "heart.fill" : "heart")
                    .font(.caption2)
                    .foregroundStyle(health.authOk ? .green : .secondary)
                    .onTapGesture { health.requestAuth() }

                if !bridge.statusText.isEmpty {
                    Text(bridge.statusText)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Text("Avvia scheda")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(bridge.groups, id: \.self) { group in
                    Button {
                        bridge.requestStartWorkout(group)
                    } label: {
                        Text(group)
                            .font(.caption2.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Workout")
    }
}

struct ActiveWorkoutView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth
    let session: WatchSession
    let exercise: WatchExercise

    private var pendingSet: WatchExerciseSet? {
        exercise.sets.first(where: { !$0.done })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.gruppo.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("\(session.currentExerciseIndex + 1)/\(session.exercises.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(3)

                HStack {
                    if let hr = health.heartRate {
                        Label("\(Int(hr))", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Label("\(Int(health.activeCalories))", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }
                .font(.caption2)

                Text(formatVolume(session.totalVolumeKg))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.yellow)

                let done = exercise.sets.filter(\.done).count
                Text("Serie \(min(done + (pendingSet == nil ? 0 : 1), exercise.sets.count))/\(exercise.sets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let next = pendingSet {
                    StepperRow(title: "Rep", value: "\(next.reps)") {
                        bridge.adjustCurrent(repsDelta: -1)
                    } plus: {
                        bridge.adjustCurrent(repsDelta: 1)
                    }
                    StepperRow(title: "Kg", value: formatKg(next.peso)) {
                        bridge.adjustCurrent(pesoDelta: -2.5)
                    } plus: {
                        bridge.adjustCurrent(pesoDelta: 2.5)
                    }

                    Button {
                        bridge.completeCurrentSet()
                    } label: {
                        Label("Serie fatta", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else if session.currentExerciseIndex < session.exercises.count - 1 {
                    Button {
                        bridge.nextExercise()
                    } label: {
                        Label("Prossimo", systemImage: "chevron.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button {
                        bridge.finishSession()
                    } label: {
                        Label("Termina", systemImage: "flag.checkered")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Button {
                    bridge.startRecovery(seconds: exercise.recSec ?? 90, label: exercise.name)
                } label: {
                    Label("Recupero \(exercise.recSec ?? 90)s", systemImage: "timer")
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                if !session.upcomingExercises.isEmpty {
                    Text("Dopo")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(session.upcomingExercises.prefix(6)) { ex in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ex.name)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(2)
                            if let first = ex.sets.first {
                                Text("\(ex.sets.count)× \(first.reps) · \(formatKg(first.peso)) kg")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
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
                }

                Button {
                    bridge.undoLastSet()
                } label: {
                    Label("Annulla set", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    bridge.finishSession()
                } label: {
                    Label("Termina", systemImage: "flag.checkered")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Serie")
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

struct RecoveryView: View {
    @EnvironmentObject var bridge: WatchSessionBridge

    var body: some View {
        VStack(spacing: 8) {
            Text("RECUPERO")
                .font(.caption2)
                .foregroundStyle(.green)
            if !bridge.recoveryLabel.isEmpty {
                Text(bridge.recoveryLabel)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            Text(timeString(bridge.recoverySecondsLeft))
                .font(.system(size: 40, weight: .black, design: .rounded))
                .monospacedDigit()
            Button("Salta") { bridge.stopRecovery() }
                .buttonStyle(.bordered)
                .tint(.gray)
        }
        .padding(.horizontal, 4)
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
                Text("FINITO")
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
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption2)

                ForEach(summary.exercises) { ex in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.caption2.weight(.bold))
                            .lineLimit(2)
                        ForEach(ex.sets) { set in
                            Text("\(set.setNumber)  \(set.reps)×\(formatKg(set.peso)) kg\(set.done ? "  ✓" : "")")
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
                    .tint(.orange)
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
