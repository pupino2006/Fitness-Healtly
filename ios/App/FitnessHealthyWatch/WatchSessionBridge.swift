import Foundation
import WatchConnectivity
import WatchKit
import Combine

final class WatchSessionBridge: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionBridge()

    @Published var session: WatchSession?
    @Published var recoverySecondsLeft: Int = 0
    @Published var isRecovering: Bool = false
    @Published var phoneReachable: Bool = false
    @Published var lastMessage: String = ""

    private var recoveryTimer: Timer?

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    func completeCurrentSet() {
        guard var sess = session, var ex = sess.currentExercise else { return }
        guard let idx = ex.sets.firstIndex(where: { !$0.done }) else { return }
        ex.sets[idx].done = true
        ex.currentSet = min(ex.sets.count, ex.sets[idx].setNumber + 1)
        sess.exercises[sess.currentExerciseIndex] = ex
        session = sess

        sendToPhone([
            "type": "setComplete",
            "exId": ex.exId,
            "setNum": ex.sets[idx].setNumber
        ])
    }

    func undoLastSet() {
        guard var sess = session, var ex = sess.currentExercise else { return }
        guard let idx = ex.sets.lastIndex(where: { $0.done }) else { return }
        ex.sets[idx].done = false
        ex.currentSet = ex.sets[idx].setNumber
        sess.exercises[sess.currentExerciseIndex] = ex
        session = sess

        sendToPhone([
            "type": "setUndo",
            "exId": ex.exId,
            "setNum": ex.sets[idx].setNumber
        ])
    }

    func nextExercise() {
        guard var sess = session else { return }
        sess.currentExerciseIndex = min(sess.exercises.count - 1, sess.currentExerciseIndex + 1)
        session = sess
        sendToPhone(["type": "nextExercise"])
    }

    func prevExercise() {
        guard var sess = session else { return }
        sess.currentExerciseIndex = max(0, sess.currentExerciseIndex - 1)
        session = sess
        sendToPhone(["type": "prevExercise"])
    }

    func finishSession() {
        sendToPhone(["type": "finishSession"])
        WatchWorkoutHealth.shared.endWorkout()
        session = nil
        stopRecovery()
    }

    func startRecovery(seconds: Int) {
        recoveryTimer?.invalidate()
        recoverySecondsLeft = seconds
        isRecovering = true
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.recoverySecondsLeft <= 1 {
                t.invalidate()
                self.isRecovering = false
                self.recoverySecondsLeft = 0
                WKInterfaceDevice.current().play(.notification)
                self.sendToPhone(["type": "recoveryDone"])
            } else {
                self.recoverySecondsLeft -= 1
                if self.recoverySecondsLeft == 10 {
                    WKInterfaceDevice.current().play(.click)
                }
            }
        }
    }

    func stopRecovery() {
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        isRecovering = false
        recoverySecondsLeft = 0
    }

    private func sendToPhone(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { err in
                print("Watch send error", err.localizedDescription)
                s.transferUserInfo(payload)
            }
        } else {
            s.transferUserInfo(payload)
        }
    }

    private func handleIncoming(_ message: [String: Any]) {
        let type = message["type"] as? String ?? ""
        DispatchQueue.main.async {
            self.lastMessage = type
            switch type {
            case "sessionSync":
                self.parseSession(message)
            case "startRecovery":
                let sec = message["seconds"] as? Int ?? 60
                self.startRecovery(seconds: sec)
            case "stopRecovery":
                self.stopRecovery()
            case "nativeWorkoutStarted":
                WatchWorkoutHealth.shared.startWorkout()
            case "nativeWorkoutEnded":
                WatchWorkoutHealth.shared.endWorkout()
                self.session = nil
            default:
                break
            }
        }
    }

    private func parseSession(_ message: [String: Any]) {
        // message itself may be the session fields, or nested under "session"
        let raw: [String: Any]
        if let nested = message["session"] as? [String: Any] {
            raw = nested
        } else {
            raw = message
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: raw, options: [])
            let decoded = try JSONDecoder().decode(WatchSession.self, from: data)
            self.session = decoded
            if !WatchWorkoutHealth.shared.isActive {
                WatchWorkoutHealth.shared.startWorkout()
            }
        } catch {
            // Fallback parsing if JS payload uses slightly different shape
            guard let id = raw["id"] as? String,
                  let gruppo = raw["gruppo"] as? String else { return }
            let startedAt = raw["startedAt"] as? String ?? ISO8601DateFormatter().string(from: Date())
            let idx = raw["currentExerciseIndex"] as? Int ?? 0
            var exercises: [WatchExercise] = []
            if let arr = raw["exercises"] as? [[String: Any]] {
                for item in arr {
                    let exId = item["exId"] as? String ?? UUID().uuidString
                    let name = item["name"] as? String ?? "Esercizio"
                    let currentSet = item["currentSet"] as? Int ?? 1
                    var sets: [WatchExerciseSet] = []
                    if let sArr = item["sets"] as? [[String: Any]] {
                        for s in sArr {
                            sets.append(WatchExerciseSet(
                                setNumber: s["set"] as? Int ?? sets.count + 1,
                                reps: s["reps"] as? Int ?? 10,
                                peso: (s["peso"] as? Double) ?? Double(s["peso"] as? Int ?? 0),
                                done: s["done"] as? Bool ?? false
                            ))
                        }
                    }
                    exercises.append(WatchExercise(exId: exId, name: name, sets: sets, currentSet: currentSet))
                }
            }
            self.session = WatchSession(
                id: id,
                gruppo: gruppo,
                startedAt: startedAt,
                exercises: exercises,
                currentExerciseIndex: idx
            )
            if !WatchWorkoutHealth.shared.isActive {
                WatchWorkoutHealth.shared.startWorkout()
            }
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.phoneReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.phoneReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncoming(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncoming(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncoming(applicationContext)
    }
}
