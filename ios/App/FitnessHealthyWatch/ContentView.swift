import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bridge: WatchSessionBridge
    @EnvironmentObject var health: WatchWorkoutHealth

    var body: some View {
        NavigationStack {
            if bridge.isRecovering {
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

                Label(bridge.phoneReachable ? "iPhone collegato" : "Apri l'app iPhone", systemImage: bridge.phoneReachable ? "iphone" : "iphone.slash")
                    .font(.caption2)

                Label(health.authOk ? "Salute OK" : "Autorizza Salute", systemImage: health.authOk ? "heart.fill" : "heart")
                    .font(.caption2)
                    .foregroundStyle(health.authOk ? .green : .secondary)
                    .onTapGesture { health.requestAuth() }

                if let pending = bridge.pendingStart {
                    Text("Avvio \(pending)…")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Text("Avvia scheda")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(bridge.availableGroups, id: \.self) { group in
                    Button {
                        bridge.requestStartWorkout(group)
                    } label: {
                        Text(group)
                            .font(.caption2.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(session.gruppo.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(3)

                HStack {
                    if let hr = health.heartRate {
                        Label("\(Int(hr))", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Label("\(Int(health.activeCalories)) kcal", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }
                .font(.caption2)

                let done = exercise.sets.filter(\.done).count
                Text("Serie \(done)/\(exercise.sets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let next = exercise.sets.first(where: { !$0.done }) {
                    Text("Prossima: \(next.reps) rep · \(Int(next.peso)) kg")
                        .font(.caption2)
                }

                Button(action: { bridge.completeCurrentSet() }) {
                    Label("Serie fatta", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)

                Button(action: {
                    bridge.startRecovery(seconds: 90)
                }) {
                    Label("Recupero 90s", systemImage: "timer")
                }
                .tint(.blue)

                HStack {
                    Button(action: { bridge.prevExercise() }) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: { bridge.nextExercise() }) {
                        Image(systemName: "chevron.right")
                    }
                }

                Button(role: .destructive, action: { bridge.undoLastSet() }) {
                    Label("Annulla set", systemImage: "arrow.uturn.backward")
                }

                Button(role: .destructive, action: { bridge.finishSession() }) {
                    Label("Termina", systemImage: "flag.checkered")
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Serie")
    }
}

struct RecoveryView: View {
    @EnvironmentObject var bridge: WatchSessionBridge

    var body: some View {
        VStack(spacing: 12) {
            Text("RECUPERO")
                .font(.caption)
                .foregroundStyle(.green)
            Text(timeString(bridge.recoverySecondsLeft))
                .font(.system(size: 40, weight: .black, design: .rounded))
                .monospacedDigit()
            Button("Skip") { bridge.stopRecovery() }
                .tint(.gray)
        }
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
