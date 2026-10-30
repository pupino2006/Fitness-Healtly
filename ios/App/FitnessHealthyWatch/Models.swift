import Foundation

struct WatchExerciseSet: Identifiable, Codable, Hashable {
    var setNumber: Int
    var reps: Int
    var peso: Double
    var done: Bool
    var note: String?
    var reps2: Int?
    var peso2: Double?
    var reps3: Int?
    var peso3: Double?

    var id: Int { setNumber }

    enum CodingKeys: String, CodingKey {
        case setNumber = "set"
        case reps, peso, done, note
        case reps2, peso2, reps3, peso3
    }

    init(setNumber: Int, reps: Int, peso: Double, done: Bool, note: String? = nil, reps2: Int? = nil, peso2: Double? = nil, reps3: Int? = nil, peso3: Double? = nil) {
        self.setNumber = setNumber
        self.reps = reps
        self.peso = peso
        self.done = done
        self.note = note
        self.reps2 = reps2
        self.peso2 = peso2
        self.reps3 = reps3
        self.peso3 = peso3
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
        reps2 = try c.decodeIfPresent(Int.self, forKey: .reps2)
        reps3 = try c.decodeIfPresent(Int.self, forKey: .reps3)
        peso2 = Self.readDouble(c, .peso2)
        peso3 = Self.readDouble(c, .peso3)
    }

    var liftedKg: Double {
        var total = Double(reps) * peso
        if let peso2 {
            total += Double(reps2 ?? reps) * peso2
        }
        if let peso3 {
            total += Double(reps3 ?? reps) * peso3
        }
        return total
    }

    private static func readDouble(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let value = try? c.decode(Double.self, forKey: key) { return value }
        if let value = try? c.decode(Int.self, forKey: key) { return Double(value) }
        return nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(setNumber, forKey: .setNumber)
        try c.encode(reps, forKey: .reps)
        try c.encode(peso, forKey: .peso)
        try c.encode(done, forKey: .done)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(reps2, forKey: .reps2)
        try c.encodeIfPresent(peso2, forKey: .peso2)
        try c.encodeIfPresent(reps3, forKey: .reps3)
        try c.encodeIfPresent(peso3, forKey: .peso3)
    }
}

struct WatchExercise: Identifiable, Codable, Hashable {
    var exId: String
    var name: String
    var sets: [WatchExerciseSet]
    var currentSet: Int
    var recSec: Int?
    var note: String?
    var partNames: [String]?

    var id: String { exId }

    var nextSetNumber: Int? {
        sets.first(where: { !$0.done })?.setNumber
    }

    enum CodingKeys: String, CodingKey {
        case exId, name, sets, currentSet, recSec, note, partNames
    }

    init(exId: String, name: String, sets: [WatchExerciseSet], currentSet: Int, recSec: Int? = nil, note: String? = nil, partNames: [String]? = nil) {
        self.exId = exId
        self.name = name
        self.sets = sets
        self.currentSet = currentSet
        self.recSec = recSec
        self.note = note
        self.partNames = partNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        exId = try c.decodeIfPresent(String.self, forKey: .exId) ?? UUID().uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Esercizio"
        sets = try c.decodeIfPresent([WatchExerciseSet].self, forKey: .sets) ?? []
        currentSet = try c.decodeIfPresent(Int.self, forKey: .currentSet) ?? (sets.first(where: { !$0.done })?.setNumber ?? 1)
        recSec = try c.decodeIfPresent(Int.self, forKey: .recSec)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        partNames = try c.decodeIfPresent([String].self, forKey: .partNames)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(exId, forKey: .exId)
        try c.encode(name, forKey: .name)
        try c.encode(sets, forKey: .sets)
        try c.encode(currentSet, forKey: .currentSet)
        try c.encodeIfPresent(recSec, forKey: .recSec)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(partNames, forKey: .partNames)
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
            acc + ex.sets.filter(\.done).reduce(0) { $0 + $1.liftedKg }
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
