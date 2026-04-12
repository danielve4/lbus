import Foundation

enum ArrayMoveError: Error {
    case invalidInput
}

extension Array {
    /// Reorders elements in-place using the same semantics as SwiftUI's
    /// `move(fromOffsets:toOffset:)`: items at `source` indices are removed,
    /// then inserted as a group at `destination` (adjusted for prior removals).
    ///
    /// Throws `ArrayMoveError.invalidInput` if any source index is out of
    /// bounds or `destination` is not in `0...count`.
    mutating func moveElements(fromOffsets source: IndexSet, toOffset destination: Int) throws {
        guard destination >= 0 && destination <= count else {
            throw ArrayMoveError.invalidInput
        }
        for index in source {
            guard index >= 0 && index < count else {
                throw ArrayMoveError.invalidInput
            }
        }

        let moving = source.map { self[$0] }
        for index in source.sorted().reversed() {
            remove(at: index)
        }
        let insertionPoint = destination - source.filter { $0 < destination }.count
        insert(contentsOf: moving, at: insertionPoint)
    }
}
