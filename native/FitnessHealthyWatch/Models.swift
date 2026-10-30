import Foundation

struct WatchExerciseSet: Identifiable, Codable, Hashable {
    var setNumber: Int
    var reps: Int
    var peso: Double
    var done: Bool
    var note: String?

    var id: Int { setNumber }

    enum CodingKeys: String, CodingKey {
        case setNumber = "set"
        case reps, peso, done, note
    }

    init(setNumber: Int, reps: Int, peso: Double, done: Bool, note: String? = nil) {
        self.setNumber = setNumber
        self.reps = reps
        self.peso = peso
        self.done = done
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        setNumber = try c.decodeIfPresent(Int.self, forKey: .setNumber) ?? 1
        reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 10
        if let value = try? c.decode(Double.self, forKey: .peso) {
            peso = value
        } else if let value = try? c.decode(Int.self, forKey: .peso) {
            peso = Double(value)
        } else {
            peso = 0
        }
        done = try c.decodeIfPresent(Bool.self, forKey: .done) ?? false
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(setNumber, forKey: .setNumber)
        try c.encode(reps, forKey: .reps)
        try c.encode(peso, forKey: .peso)
        try c.encode(done, forKey: .done)
        try c.encodeIfPresent(note, forKey: .note)
    }
}

struct WatchExercise: Identifiable, Codable, Hashable {
    var exId: String
    var name: String
    var sets: [WatchExerciseSet]
    var currentSet: Int
    var recSec: Int?
    var note: String?

    var id: String { exId }

    var nextSetNumber: Int? {
        sets.first(where: { !$0.done })?.setNumber
    }

    enum CodingKeys: String, CodingKey {
        case exId, name, sets, currentSet, recSec, note
    }

    init(exId: String, name: String, sets: [WatchExerciseSet], currentSet: Int, recSec: Int? = nil, note: String? = nil) {
        self.exId = exId
        self.name = name
        self.sets = sets
        self.currentSet = currentSet
        self.recSec = recSec
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exId = try c.decodeIfPresent(String.self, forKey: .exId) ?? UUID().uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Esercizio"
        sets = try c.decodeIfPresent([WatchExerciseSet].self, forKey: .sets) ?? []
        currentSet = try c.decodeIfPresent(Int.self, forKey: .currentSet) ?? (sets.first(where: { !$0.done })?.setNumber ?? 1)
        recSec = try c.decodeIfPresent(Int.self, forKey: .recSec)
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(exId, forKey: .exId)
        try c.encode(name, forKey: .name)
        try c.encode(sets, forKey: .sets)
        try c.encode(currentSet, forKey: .currentSet)
        try c.encodeIfPresent(recSec, forKey: .recSec)
        try c.encodeIfPresent(note, forKey: .note)
    }
}

struct WatchSession: Codable, Hashable {
    var id: String
    var gruppo: String
    var startedAt: String
    var exercises: [WatchExercise]
    var currentExerciseIndex: Int
    var revision: Int?

    var currentExercise: WatchExercise? {
        guard currentExerciseIndex >= 0, currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var upcomingExercises: [WatchExercise] {
        let start = currentExerciseIndex + 1
        guard start < exercises.count else { return [] }
        return Array(exercises[start...])
    }

    var totalVolumeKg: Double {
        exercises.reduce(0) { acc, ex in
            acc + ex.sets.filter(\.done).reduce(0) { $0 + (Double($1.reps) * $1.peso) }
        }
    }
}

struct WatchPlan: Codable, Hashable, Identifiable {
    var gruppo: String
    var exercises: [WatchExercise]

    var id: String { gruppo }
}

struct WatchSummary: Identifiable, Codable, Hashable {
    var id: String
    var gruppo: String
    var startedAt: String
    var endedAt: String
    var durationSec: Int
    var activeCalories: Double
    var averageHeartRate: Double?
    var totalVolumeKg: Double
    var exercises: [WatchExercise]
}
