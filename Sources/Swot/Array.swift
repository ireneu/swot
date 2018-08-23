
extension Array where Element == ChangesetOperation {
    mutating func chain(_ operation: ChangesetOperation) {
        switch (self.last, operation) {
        case (let last as Keep, let new as Keep):
            self.replaceLast(by: Keep(value: last.value + new.value))
        case (let last as Add, let new as Add):
            self.replaceLast(by: Add(value: last.value + new.value))
        case (let last as Remove, let new as Remove):
            self.replaceLast(by: Remove(value: last.value + new.value))
        default:
            self.append(operation)
        }
    }
    
    mutating func prepend(_ newElement: ChangesetOperation) {
        insert(newElement, at: 0)
    }
    
    mutating func replaceLast(by operation: ChangesetOperation) {
        self = Array(self.dropLast())
        self.append(operation)
    }
    
    mutating func replaceFirst(by operation: ChangesetOperation) {
        self = Array(self.dropFirst())
        self.prepend(operation)
    }
    
    mutating func attemptToRemoveFirst() {
        if !self.isEmpty { self.removeFirst() }
    }
}
