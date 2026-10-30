import Foundation
import Capacitor
import HealthKit
import WatchConnectivity

@objc(WorkoutBridgePlugin)
public class WorkoutBridgePlugin: CAPPlugin, CAPBridgedPlugin, WCSessionDelegate {
    public let identifier = "WorkoutBridgePlugin"
    public let jsName = "WorkoutBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startNativeWorkout", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endNativeWorkout", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getLiveMetrics", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "syncSessionToWatch", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "syncGroupsToWatch", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "syncPlansToWatch", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startWatchRecovery", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopWatchRecovery", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isNativeAvailable", returnType: CAPPluginReturnPromise)
    ]

    private let healthStore = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?
    private var workoutStart: Date?
    private var currentSessionId: String?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var latestHeartRate: Double?
    private var caloriesQuery: HKStatisticsQuery?
    private var latestCalories: Double = 0

    public override func load() {
        activateWatchSession()
    }

    private func activateWatchSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    @objc public override func requestPermissions(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.resolve(["granted": false])
            return
        }

        var share: Set<HKSampleType> = []
        var read: Set<HKObjectType> = []

        if let workout = HKObjectType.workoutType() as HKSampleType? {
            share.insert(workout)
            read.insert(workout)
        }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            read.insert(hr)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            share.insert(energy)
            read.insert(energy)
        }

        healthStore.requestAuthorization(toShare: share, read: read) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve(["granted": granted])
                }
            }
        }
    }

    @objc public func startNativeWorkout(_ call: CAPPluginCall) {
        let sessionId = call.getString("sessionId") ?? UUID().uuidString
        let gruppo = call.getString("gruppo") ?? "Workout"
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let start = Date()
        self.workoutStart = start
        self.currentSessionId = sessionId
        self.latestCalories = 0
        self.latestHeartRate = nil

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        self.workoutBuilder = builder

        builder.beginCollection(withStart: start) { [weak self] success, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    call.reject(error.localizedDescription)
                    return
                }
                self.startHeartRateObserver()
                self.startCaloriesObserver(from: start)

                // Notifica Watch: workout nativo avviato
                self.sendToWatch([
                    "type": "nativeWorkoutStarted",
                    "sessionId": sessionId,
                    "gruppo": gruppo,
                    "startedAt": ISO8601DateFormatter().string(from: start)
                ])

                call.resolve(["ok": success])
            }
        }
    }

    @objc public func endNativeWorkout(_ call: CAPPluginCall) {
        let endedSessionId = call.getString("sessionId") ?? currentSessionId
        guard let builder = workoutBuilder, let start = workoutStart else {
            // Phone may have adopted a Watch-owned session without starting HealthKit locally.
            // Still tell the Watch to stop that specific session (id-scoped).
            var payload: [String: Any] = [
                "type": "nativeWorkoutEnded",
                "durationSeconds": 0,
                "activeCalories": NSNull()
            ]
            if let endedSessionId { payload["sessionId"] = endedSessionId }
            sendToWatch(payload)
            currentSessionId = nil
            call.resolve([
                "ok": false,
                "activeCalories": NSNull(),
                "averageHeartRate": latestHeartRate as Any,
                "durationSeconds": 0
            ])
            return
        }

        let end = Date()
        stopQueries()

        builder.endCollection(withEnd: end) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            builder.finishWorkout { workout, error in
                DispatchQueue.main.async {
                    if let error = error {
                        call.reject(error.localizedDescription)
                        return
                    }
                    let duration = Int(end.timeIntervalSince(start))
                    let kcal = workout?.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                        ?? self.latestCalories

                    var payload: [String: Any] = [
                        "type": "nativeWorkoutEnded",
                        "durationSeconds": duration,
                        "activeCalories": kcal
                    ]
                    if let endedSessionId { payload["sessionId"] = endedSessionId }
                    self.sendToWatch(payload)

                    self.workoutBuilder = nil
                    self.workoutStart = nil
                    self.currentSessionId = nil

                    call.resolve([
                        "ok": true,
                        "activeCalories": kcal,
                        "averageHeartRate": self.latestHeartRate as Any,
                        "durationSeconds": duration
                    ])
                }
            }
        }
    }

    @objc public func getLiveMetrics(_ call: CAPPluginCall) {
        let elapsed: Int
        if let start = workoutStart {
            elapsed = Int(Date().timeIntervalSince(start))
        } else {
            elapsed = 0
        }
        call.resolve([
            "heartRate": latestHeartRate as Any,
            "activeCalories": latestCalories,
            "elapsedSeconds": elapsed,
            "isActive": workoutBuilder != nil
        ])
    }

    @objc public func syncSessionToWatch(_ call: CAPPluginCall) {
        guard let session = call.getObject("session") else {
            call.reject("session required")
            return
        }
        var payload = session
        payload["type"] = "sessionSync"
        sendToWatch(payload)
        call.resolve(["ok": true])
    }

    @objc public func syncGroupsToWatch(_ call: CAPPluginCall) {
        let groups = call.getArray("groups", String.self) ?? []
        sendToWatch([
            "type": "availableGroups",
            "groups": groups
        ])
        call.resolve(["ok": true, "count": groups.count])
    }

    @objc public func syncPlansToWatch(_ call: CAPPluginCall) {
        let plans = call.options["plans"] ?? []
        let phoneEdited = call.getBool("phoneEdited") ?? false
        sendToWatch([
            "type": "plansSync",
            "plans": plans,
            "phoneEdited": phoneEdited
        ])
        let count = (plans as? [Any])?.count ?? 0
        call.resolve(["ok": true, "count": count])
    }

    @objc public func startWatchRecovery(_ call: CAPPluginCall) {
        let seconds = call.getInt("seconds") ?? 60
        let name = call.getString("exerciseName") ?? ""
        sendToWatch([
            "type": "startRecovery",
            "seconds": seconds,
            "exerciseName": name
        ])
        call.resolve(["ok": true])
    }

    @objc public func stopWatchRecovery(_ call: CAPPluginCall) {
        sendToWatch(["type": "stopRecovery"])
        call.resolve(["ok": true])
    }

    @objc public func isNativeAvailable(_ call: CAPPluginCall) {
        var reachable = false
        if WCSession.isSupported() {
            reachable = WCSession.default.isReachable
        }
        call.resolve([
            "available": true,
            "watchReachable": reachable
        ])
    }

    // MARK: - HealthKit observers

    private func startHeartRateObserver() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: workoutStart, end: nil, options: .strictStartDate)

        let query = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            self?.consumeHeartRate(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.consumeHeartRate(samples)
        }
        heartRateQuery = query
        healthStore.execute(query)
    }

    private func consumeHeartRate(_ samples: [HKSample]?) {
        guard let qty = samples?.compactMap({ $0 as? HKQuantitySample }).last else { return }
        let bpm = qty.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        latestHeartRate = bpm
        notifyListeners("watchEvent", data: [
            "type": "metrics",
            "heartRate": bpm,
            "activeCalories": latestCalories
        ])
    }

    private func startCaloriesObserver(from start: Date) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        // Poll periodico via timer semplice
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] timer in
            guard let self = self, self.workoutBuilder != nil else {
                timer.invalidate()
                return
            }
            let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
            let q = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: pred, options: .cumulativeSum) { [weak self] _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async {
                    self?.latestCalories = val
                }
            }
            self.healthStore.execute(q)
        }
    }

    private func stopQueries() {
        if let q = heartRateQuery {
            healthStore.stop(q)
            heartRateQuery = nil
        }
    }

    // MARK: - WatchConnectivity

    private func sendToWatch(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let type = payload["type"] as? String ?? ""
        let durable = type == "plansSync" || type == "sessionSync" || type == "availableGroups"
        if durable {
            session.transferUserInfo(payload)
            try? session.updateApplicationContext(payload)
        }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                print("WC sendMessage error:", error.localizedDescription)
                if !durable {
                    session.transferUserInfo(payload)
                }
            }
        } else if !durable {
            session.transferUserInfo(payload)
            try? session.updateApplicationContext(payload)
        }
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.notifyListeners("watchEvent", data: message)
        }
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async {
            self.notifyListeners("watchEvent", data: userInfo)
        }
    }
}
