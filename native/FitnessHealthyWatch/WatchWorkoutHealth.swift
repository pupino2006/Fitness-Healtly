import Foundation
import HealthKit
import Combine
import WatchConnectivity

final class WatchWorkoutHealth: NSObject, ObservableObject {
    static let shared = WatchWorkoutHealth()

    @Published var isActive = false
    @Published var heartRate: Double?
    @Published var activeCalories: Double = 0
    @Published var authOk = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var metricsTimer: Timer?

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
                self.startMetricsPush()
            }
        } catch {
            print("Watch HK start error", error.localizedDescription)
        }
    }

    func endWorkout() {
        stopMetricsPush()
        session?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in
                DispatchQueue.main.async {
                    self?.isActive = false
                    self?.session = nil
                    self?.builder = nil
                    self?.heartRate = nil
                    self?.activeCalories = 0
                }
            }
        }
    }

    private func startMetricsPush() {
        stopMetricsPush()
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.pushMetricsToPhone()
        }
    }

    private func stopMetricsPush() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }

    private func pushMetricsToPhone() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        var payload: [String: Any] = [
            "type": "metrics",
            "activeCalories": activeCalories
        ]
        if let hr = heartRate { payload["heartRate"] = hr }
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { _ in
                s.transferUserInfo(payload)
            }
        } else {
            s.transferUserInfo(payload)
        }
    }
}

extension WatchWorkoutHealth: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isActive = false
            self.stopMetricsPush()
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
                    self.heartRate = stats?.mostRecentQuantity()?.doubleValue(for: unit)
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    self.activeCalories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                default:
                    break
                }
                self.pushMetricsToPhone()
            }
        }
    }
}
