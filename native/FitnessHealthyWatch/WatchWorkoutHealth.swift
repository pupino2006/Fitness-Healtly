import Foundation
import HealthKit
import Combine
import WatchConnectivity

final class WatchWorkoutHealth: NSObject, ObservableObject {
    static let shared = WatchWorkoutHealth()

    @Published var isActive = false
    @Published var heartRate: Double?
    @Published var averageHeartRate: Double?
    @Published var activeCalories: Double = 0
    @Published var authOk = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var hrSum: Double = 0
    private var hrCount: Int = 0
    private var lastMetricsPush = Date.distantPast

    func requestAuth() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let read: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        store.requestAuthorization(toShare: share, read: read) { ok, _ in
            DispatchQueue.main.async { self.authOk = ok }
        }
    }

    func startWorkout() {
        guard session == nil else { return }
        requestAuth()
        hrSum = 0
        hrCount = 0

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            self.session = s
            self.builder = b
            let start = Date()
            s.startActivity(with: start)
            b.beginCollection(withStart: start) { _, _ in }
            DispatchQueue.main.async {
                self.isActive = true
                self.averageHeartRate = nil
                self.heartRate = nil
                self.activeCalories = 0
            }
        } catch {
            print("Watch HK start error", error.localizedDescription)
        }
    }

    func endWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in
                DispatchQueue.main.async {
                    self?.isActive = false
                    self?.session = nil
                    self?.builder = nil
                }
            }
        }
    }

    /// Invia FC/kcal solo se l'iPhone è davvero raggiungibile, e al massimo ogni 8 secondi.
    /// Con il telefono bloccato non si accoda nulla: i tasti del Watch restano immediati.
    private func pushMetricsToPhone() {
        let now = Date()
        guard now.timeIntervalSince(lastMetricsPush) > 8 else { return }
        lastMetricsPush = now
        var payload: [String: Any] = [
            "type": "metrics",
            "activeCalories": activeCalories
        ]
        if let hr = heartRate { payload["heartRate"] = hr }
        DispatchQueue.global(qos: .utility).async {
            guard WCSession.isSupported() else { return }
            let s = WCSession.default
            guard s.activationState == .activated, s.isReachable else { return }
            s.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension WatchWorkoutHealth: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isActive = false
        }
    }
}

extension WatchWorkoutHealth: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let qType = type as? HKQuantityType else { continue }
            let stats = workoutBuilder.statistics(for: qType)
            DispatchQueue.main.async {
                switch qType.identifier {
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    if let bpm = stats?.mostRecentQuantity()?.doubleValue(for: unit) {
                        self.heartRate = bpm
                        self.hrSum += bpm
                        self.hrCount += 1
                        self.averageHeartRate = self.hrSum / Double(self.hrCount)
                    }
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    self.activeCalories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? self.activeCalories
                default:
                    break
                }
                self.pushMetricsToPhone()
            }
        }
    }
}
