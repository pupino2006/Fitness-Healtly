import Foundation
import WatchConnectivity
import WatchKit
import Combine

final class WatchSessionBridge: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionBridge()

    @Published var session: WatchSession?
    @Published var summary: WatchSummary?
    @Published var recoverySecondsLeft: Int = 0
    @Published var isRecovering: Bool = false
    @Published var recoveryLabel: String = ""
    @Published var phoneReachable: Bool = false
    @Published var plansReady: Bool = false
    @Published var statusText: String = ""
    @Published var plans: [WatchPlan] = []

    private var recoveryTimer: Timer?
    private var localRevision: Int = 0
    private var weightsDirty = false
    private var lastFinishedId: String?
    private var pushWork: DispatchWorkItem?
    private let defaults = UserDefaults.standard
    private let plansKey = "fh.watch.plans.v1"
    private let sessionKey = "fh.watch.session.v1"
    private let revisionKey = "fh.watch.revision.v1"
    private let dirtyKey = "fh.watch.weightsDirty.v1"

    var groups: [String] {
        if !plans.isEmpty { return plans.map(\.gruppo) }
        return [
            "Spinte 1", "Gambe 1", "Tirata 1",
            "SS Gambe/Dorso 1", "SS Petto/Spalle 1",
            "Spalle/Petto", "Gambe 2", "Schiena 2",
            "SS Gambe/Dorso 2", "SS Petto/Spalle 2"
        ]
    }

    func activate() {
        loadPersisted()
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    func requestStartWorkout(_ gruppo: String) {
        summary = nil
        guard let plan = plans.first(where: { $0.gruppo == gruppo }) else {
            statusText = "Scheda non ancora sul Watch. Apri l'app sull'iPhone una volta, sbloccato."
            deliver([
                "type": "startWorkoutFromWatch",
                "gruppo": gruppo
            ])
            return
        }

        var exercises = plan.exercises
        for i in exercises.indices {
            for j in exercises[i].sets.indices {
                exercises[i].sets[j].done = false
            }
            exercises[i].currentSet = exercises[i].sets.first?.setNumber ?? 1
        }
        localRevision += 1
        let started = Self.isoString(Date())
        let sess = WatchSession(
            id: "w_\(Int(Date().timeIntervalSince1970))",
            gruppo: gruppo,
            startedAt: started,
            exercises: exercises,
            currentExerciseIndex: 0,
            revision: localRevision
        )
        session = sess
        statusText = ""
        persistSession()
        if !WatchWorkoutHealth.shared.isActive {
            WatchWorkoutHealth.shared.startWorkout()
        }
        pushStateToPhone()
    }

    func completeCurrentSet() {
        guard var sess = session, var ex = sess.currentExercise else { return }
        guard let idx = ex.sets.firstIndex(where: { !$0.done }) else { return }
        ex.sets[idx].done = true
        ex.currentSet = ex.sets.first(where: { !$0.done })?.setNumber ?? ex.sets.count
        sess.exercises[sess.currentExerciseIndex] = ex
        commit(sess)
        rememberWeights(from: sess)

        let stillOpen = sess.exercises.contains { $0.sets.contains { !$0.done } }
        let rec = ex.recSec ?? 90
        if stillOpen && rec > 0 {
            startRecovery(seconds: rec, label: ex.name)
        }
    }

    func adjustCurrent(repsDelta: Int = 0, pesoDelta: Double = 0) {
        guard var sess = session, var ex = sess.currentExercise else { return }
        guard let idx = ex.sets.firstIndex(where: { !$0.done }) ?? ex.sets.indices.last else { return }
        if repsDelta != 0 {
            ex.sets[idx].reps = min(40, max(1, ex.sets[idx].reps + repsDelta))
        }
        if pesoDelta != 0 {
            let next = ex.sets[idx].peso + pesoDelta
            ex.sets[idx].peso = max(0, (next * 2).rounded() / 2)
        }
        sess.exercises[sess.currentExerciseIndex] = ex
        commit(sess)
        rememberWeights(from: sess)
    }

    func undoLastSet() {
        guard var sess = session, var ex = sess.currentExercise else { return }
        guard let idx = ex.sets.lastIndex(where: { $0.done }) else { return }
        ex.sets[idx].done = false
        ex.currentSet = ex.sets[idx].setNumber
        sess.exercises[sess.currentExerciseIndex] = ex
        commit(sess)
        stopRecovery()
    }

    func nextExercise() {
        guard var sess = session else { return }
        let next = min(sess.exercises.count - 1, sess.currentExerciseIndex + 1)
        guard next != sess.currentExerciseIndex else { return }
        sess.currentExerciseIndex = next
        commit(sess)
        stopRecovery()
    }

    func prevExercise() {
        guard var sess = session else { return }
        let prev = max(0, sess.currentExerciseIndex - 1)
        guard prev != sess.currentExerciseIndex else { return }
        sess.currentExerciseIndex = prev
        commit(sess)
        stopRecovery()
    }

    func finishSession() {
        guard let sess = session else { return }
        pushWork?.cancel()
        let health = WatchWorkoutHealth.shared
        let ended = Date()
        let start = Self.parseDate(sess.startedAt) ?? ended
        let duration = max(0, Int(ended.timeIntervalSince(start)))
        let built = WatchSummary(
            id: sess.id,
            gruppo: sess.gruppo,
            startedAt: sess.startedAt,
            endedAt: Self.isoString(ended),
            durationSec: duration,
            activeCalories: health.activeCalories,
            averageHeartRate: health.averageHeartRate ?? health.heartRate,
            totalVolumeKg: sess.totalVolumeKg,
            exercises: sess.exercises
        )
        summary = built
        lastFinishedId = sess.id
        session = nil
        stopRecovery()
        clearPersistedSession()
        health.endWorkout()
        if var payload = Self.encode(built) {
            payload["type"] = "watchWorkoutFinished"
            payload["revision"] = localRevision
            deliver(payload)
        }
    }

    func dismissSummary() {
        summary = nil
    }

    func startRecovery(seconds: Int, label: String = "") {
        recoveryTimer?.invalidate()
        recoverySecondsLeft = seconds
        recoveryLabel = label
        isRecovering = true
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.recoverySecondsLeft <= 1 {
                t.invalidate()
                self.isRecovering = false
                self.recoverySecondsLeft = 0
                WKInterfaceDevice.current().play(.notification)
            } else {
                self.recoverySecondsLeft -= 1
                if self.recoverySecondsLeft == 10 || self.recoverySecondsLeft == 3 {
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
        recoveryLabel = ""
    }

    // MARK: - Persistenza locale

    private func loadPersisted() {
        localRevision = defaults.integer(forKey: revisionKey)
        weightsDirty = defaults.bool(forKey: dirtyKey)
        if let data = defaults.data(forKey: plansKey),
           let saved = try? JSONDecoder().decode([WatchPlan].self, from: data) {
            plans = saved
            plansReady = !saved.isEmpty
        }
        if let data = defaults.data(forKey: sessionKey),
           let saved = try? JSONDecoder().decode(WatchSession.self, from: data),
           let start = Self.parseDate(saved.startedAt),
           Date().timeIntervalSince(start) < 18 * 3600 {
            session = saved
            localRevision = max(localRevision, saved.revision ?? localRevision)
            if !WatchWorkoutHealth.shared.isActive {
                WatchWorkoutHealth.shared.startWorkout()
            }
        } else {
            defaults.removeObject(forKey: sessionKey)
        }
    }

    private func persistSession() {
        defaults.set(localRevision, forKey: revisionKey)
        guard let session else {
            defaults.removeObject(forKey: sessionKey)
            return
        }
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: sessionKey)
        }
    }

    private func clearPersistedSession() {
        defaults.set(localRevision, forKey: revisionKey)
        defaults.removeObject(forKey: sessionKey)
    }

    private func persistPlans() {
        plansReady = !plans.isEmpty
        defaults.set(weightsDirty, forKey: dirtyKey)
        if let data = try? JSONEncoder().encode(plans) {
            defaults.set(data, forKey: plansKey)
        }
    }

    private func commit(_ sess: WatchSession) {
        var copy = sess
        localRevision += 1
        copy.revision = localRevision
        session = copy
        persistSession()
        pushStateToPhone()
    }

    private func rememberWeights(from sess: WatchSession) {
        guard let idx = plans.firstIndex(where: { $0.gruppo == sess.gruppo }) else { return }
        var plan = plans[idx]
        for ex in sess.exercises {
            guard let ei = plan.exercises.firstIndex(where: { $0.exId == ex.exId }) else { continue }
            for set in ex.sets {
                guard let si = plan.exercises[ei].sets.firstIndex(where: { $0.setNumber == set.setNumber }) else { continue }
                plan.exercises[ei].sets[si].reps = set.reps
                plan.exercises[ei].sets[si].peso = set.peso
                plan.exercises[ei].sets[si].done = false
            }
        }
        plans[idx] = plan
        weightsDirty = true
        persistPlans()
    }

    // MARK: - Telefono, solo in uscita e mai bloccante

    private func pushStateToPhone() {
        pushWork?.cancel()
        guard let session, var payload = Self.encode(session) else { return }
        payload["type"] = "watchSessionState"
        payload["revision"] = localRevision
        let item = DispatchWorkItem { [payload] in
            Self.deliverStatic(payload)
        }
        pushWork = item
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.2, execute: item)
    }

    private func deliver(_ payload: [String: Any]) {
        DispatchQueue.global(qos: .utility).async {
            Self.deliverStatic(payload)
        }
    }

    private static func deliverStatic(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        guard s.activationState == .activated else { return }
        guard let safe = sanitize(payload) as? [String: Any] else { return }
        s.transferUserInfo(safe)
        if s.isReachable {
            s.sendMessage(safe, replyHandler: nil, errorHandler: nil)
        } else {
            try? s.updateApplicationContext(safe)
        }
    }

    private func handleIncoming(_ message: [String: Any]) {
        let type = message["type"] as? String ?? ""
        DispatchQueue.main.async {
            switch type {
            case "sessionSync":
                self.applyRemoteSession(message)
            case "plansSync":
                self.applyRemotePlans(message)
            case "startRecovery":
                let sec = message["seconds"] as? Int ?? 60
                let name = message["exerciseName"] as? String ?? ""
                self.startRecovery(seconds: sec, label: name)
            case "stopRecovery":
                self.stopRecovery()
            case "nativeWorkoutStarted":
                if self.session == nil && self.summary == nil {
                    WatchWorkoutHealth.shared.startWorkout()
                }
            case "nativeWorkoutEnded":
                if self.session != nil {
                    WatchWorkoutHealth.shared.endWorkout()
                    self.session = nil
                    self.clearPersistedSession()
                    self.stopRecovery()
                }
            case "availableGroups":
                break
            default:
                break
            }
        }
    }

    private func applyRemoteSession(_ message: [String: Any]) {
        guard summary == nil else { return }
        let raw = Self.sanitize((message["session"] as? [String: Any]) ?? message)
        guard let decoded = Self.decode(WatchSession.self, from: raw) else { return }
        if decoded.id == lastFinishedId { return }
        let remoteRev = (message["revision"] as? Int) ?? decoded.revision ?? 0

        if session == nil {
            localRevision = max(remoteRev, 1)
            var copy = decoded
            copy.revision = localRevision
            session = copy
            statusText = ""
            persistSession()
            if !WatchWorkoutHealth.shared.isActive {
                WatchWorkoutHealth.shared.startWorkout()
            }
            return
        }

        guard decoded.id == session?.id, remoteRev > localRevision else { return }
        localRevision = remoteRev
        session = decoded
        persistSession()
    }

    private func applyRemotePlans(_ message: [String: Any]) {
        let phoneEdited = Self.boolValue(message["phoneEdited"])
        let rawPlans = message["plans"] as? [Any] ?? []
        let clean = Self.sanitize(rawPlans)
        guard let incoming = Self.decode([WatchPlan].self, from: clean), !incoming.isEmpty else { return }

        if weightsDirty && !phoneEdited {
            let merged = incoming.map { remote -> WatchPlan in
                guard let local = self.plans.first(where: { $0.gruppo == remote.gruppo }) else { return remote }
                var copy = remote
                for i in copy.exercises.indices {
                    guard let localEx = local.exercises.first(where: { $0.exId == copy.exercises[i].exId }) else { continue }
                    for j in copy.exercises[i].sets.indices {
                        let n = copy.exercises[i].sets[j].setNumber
                        guard let localSet = localEx.sets.first(where: { $0.setNumber == n }) else { continue }
                        copy.exercises[i].sets[j].peso = localSet.peso
                        copy.exercises[i].sets[j].reps = localSet.reps
                        copy.exercises[i].sets[j].done = false
                    }
                }
                return copy
            }
            if Self.sameWeights(incoming, merged) {
                weightsDirty = false
                plans = incoming
            } else {
                plans = merged
            }
        } else {
            plans = incoming
            weightsDirty = false
        }
        persistPlans()
        statusText = ""
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.phoneReachable = session.isReachable
            if activationState == .activated, let ctx = Self.nonEmpty(session.receivedApplicationContext) {
                self.handleIncoming(ctx)
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.phoneReachable = session.isReachable
            if session.isReachable, self.session != nil {
                self.pushStateToPhone()
            }
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

    // MARK: - JSON helpers

    private static func encode<T: Encodable>(_ value: T) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(value),
              let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return sanitize(obj) as? [String: Any]
    }

    private static func decode<T: Decodable>(_ type: T.Type, from value: Any) -> T? {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }

    private static func sanitize(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var out: [String: Any] = [:]
            for (key, item) in dict {
                if item is NSNull { continue }
                out[key] = sanitize(item)
            }
            return out
        }
        if let array = value as? [Any] {
            return array.compactMap { item -> Any? in
                if item is NSNull { return nil }
                return sanitize(item)
            }
        }
        return value
    }

    private static func nonEmpty(_ dict: [String: Any]) -> [String: Any]? {
        dict.isEmpty ? nil : dict
    }

    private static func sameWeights(_ a: [WatchPlan], _ b: [WatchPlan]) -> Bool {
        guard a.count == b.count else { return false }
        for plan in a {
            guard let other = b.first(where: { $0.gruppo == plan.gruppo }) else { return false }
            for ex in plan.exercises {
                guard let ox = other.exercises.first(where: { $0.exId == ex.exId }) else { return false }
                for set in ex.sets {
                    guard let os = ox.sets.first(where: { $0.setNumber == set.setNumber }) else { return false }
                    if os.reps != set.reps || abs(os.peso - set.peso) > 0.01 { return false }
                }
            }
        }
        return true
    }

    private static func isoString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    static func parseDate(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = f.date(from: string) { return date }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: string)
    }
}
