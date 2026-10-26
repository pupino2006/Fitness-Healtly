import Foundation

struct WatchExerciseSet: Identifiable, Codable, Hashable {
    var setNumber: Int
    var reps: Int
    var peso: Double
    var done: Bool

    var id: Int { setNumber }

    enum CodingKeys: String, CodingKey {
        case setNumber = "set"
        case reps, peso, done
    }
}

struct WatchExercise: Identifiable, Codable, Hashable {
    var exId: String
    var name: String
    var sets: [WatchExerciseSet]
    var currentSet: Int

    var id: String { exId }

    var nextSetNumber: Int? {
        sets.first(where: { !$0.done })?.setNumber
    }
}

struct WatchSession: Codable, Hashable {
    var id: String
    var gruppo: String
    var startedAt: String
    var exercises: [WatchExercise]
    var currentExerciseIndex: Int

    var currentExercise: WatchExercise? {
        guard currentExerciseIndex >= 0, currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
}
