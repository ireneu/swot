
struct Changeset {
    let operations: [Operation]
    
    var fromLength: Int { return operations.filter { !($0 is Add) }.map { $0.length }.reduce(0, +) }
    var toLength: Int { return self.operations.filter { !($0 is Remove) }.map { $0.length }.reduce(0, +) }
    
    enum ChangesetError: Error {
        case badTextLength
        case uncomposableChangesets
        case uncombinableChangesets
    }
    
    init(operations: [Operation] = [Operation]()) {
        var chainedOperations = [Operation]()
        operations.forEach { chainedOperations.chain($0) }
        self.operations = chainedOperations
    }
    
    func apply(to text: String) throws -> String {
        // Swift does not guarantee TCO (Tail Call Optimization) so going for an iterative version.
        guard fromLength == text.count else {
            throw ChangesetError.badTextLength
        }
        
        var position = text.startIndex
        var changedText = ""
        for operation in operations {
            switch operation {
            case is Keep:
                let newPosition = text.index(position, offsetBy: operation.length)
                changedText.append(String(text[position..<newPosition]))
                position = newPosition
            case let operation as Add:
                changedText.append(operation.value)
            case is Remove:
                text.formIndex(&position, offsetBy: operation.length)
            default:
                fatalError()
            }
        }
        return changedText
    }
}


infix operator >>>
infix operator <~>
extension Changeset {
    static func >>>(lhs: Changeset, rhs: Changeset) throws -> Changeset {
        guard lhs.toLength == rhs.fromLength else { throw ChangesetError.uncomposableChangesets }
        
        guard !lhs.operations.isEmpty else { return rhs }
        guard !rhs.operations.isEmpty else { return lhs }
        
        var composedOperations = [Operation]()
        var left = lhs.operations
        var right = rhs.operations
        var finished = false
        
        while !finished {
            switch (left.first, right.first) {
            case (is Remove, _):
                composedOperations.chain(left.removeFirst())
            case (_, is Add):
                composedOperations.chain(right.removeFirst())
            case (let l as Keep, let r as Keep):
                if l.length < r.length {
                    composedOperations.chain(l)
                    left.removeFirst()
                    right.replaceFirst(by: Keep(value: r.length - l.length))
                } else if l.length == r.length {
                    composedOperations.chain(l)
                    left.removeFirst()
                    right.removeFirst()
                } else if l.length > r.length {
                    composedOperations.chain(r)
                    left.replaceFirst(by: Keep(value: l.length - r.length))
                    right.removeFirst()
                }
            case (let l as Keep, let r as Remove):
                if l.length < r.length {
                    composedOperations.chain(Remove(value: l.length))
                    left.removeFirst()
                    right.replaceFirst(by: Remove(value: r.length - l.length))
                } else if l.length == r.length {
                    composedOperations.chain(r)
                    left.removeFirst()
                    right.removeFirst()
                } else if l.length > r.length {
                    composedOperations.chain(r)
                    left.replaceFirst(by: Keep(value: l.length - r.length))
                    right.removeFirst()
                }
            case (let l as Add, let r as Keep):
                if l.length < r.length {
                    composedOperations.chain(l)
                    left.removeFirst()
                    right.replaceFirst(by: Keep(value: r.length - l.length))
                } else if l.length == r.length {
                    composedOperations.chain(l)
                    left.removeFirst()
                    right.removeFirst()
                } else if l.length > r.length {
                    let i = l.value.index(l.value.startIndex, offsetBy: l.length - r.length)
                    composedOperations.chain(Add(value: String(l.value[..<i])))
                    left.replaceFirst(by: Add(value: String(l.value[i...])))
                    right.removeFirst()
                }
            case (let l as Add, let r as Remove):
                if l.length < r.length {
                    left.removeFirst()
                    right.replaceFirst(by: Remove(value: r.length - l.length))
                } else if l.length == r.length {
                    left.removeFirst()
                    right.removeFirst()
                } else if l.length > r.length {
                    let i = l.value.index(l.value.startIndex, offsetBy: l.length - r.length)
                    left.replaceFirst(by: Add(value: String(l.value[i...])))
                    right.removeFirst()
                }
            default:
                fatalError("Unknown operation combination when trying to compose two changesets")
            }
            
            if left.isEmpty && right.isEmpty { finished = true }
        }
        
        return Changeset(operations: composedOperations)
    }
    
    static func <~>(lhs: Changeset, rhs: Changeset) throws -> (left: Changeset, right: Changeset) {
        guard lhs.fromLength == rhs.fromLength else { throw ChangesetError.uncombinableChangesets }
        
        var lPrime = [Operation]()
        var rPrime = [Operation]()
        var left = lhs.operations
        var right = rhs.operations
        var finished = false
        
        while !finished {
            switch (left.first ?? Keep(value: 0), right.first ?? Keep(value: 0)) {
            case (let l as Add, _):
                lPrime.chain(l)
                rPrime.chain(Keep(value: l.length))
                left.attemptToRemoveFirst()
            case (_, let r as Add):
                lPrime.chain(Keep(value: r.length))
                rPrime.chain(r)
                right.attemptToRemoveFirst()
            case (let l as Keep, let r as Keep):
                if l.length < r.length {
                    lPrime.chain(l)
                    rPrime.chain(l)
                    left.attemptToRemoveFirst()
                    right.replaceFirst(by: Keep(value: r.length - l.length))
                } else if l.length == r.length {
                    lPrime.chain(l)
                    rPrime.chain(r)
                    left.attemptToRemoveFirst()
                    right.attemptToRemoveFirst()
                } else if l.length > r.length {
                    lPrime.chain(r)
                    rPrime.chain(r)
                    left.replaceFirst(by: Keep(value: l.length - r.length))
                    right.attemptToRemoveFirst()
                }
            case (let l as Remove, let r as Remove):
                if l.length < r.length {
                    left.attemptToRemoveFirst()
                    right.replaceFirst(by: Remove(value: r.length - l.length))
                } else if l.length == r.length {
                    left.attemptToRemoveFirst()
                    right.attemptToRemoveFirst()
                } else if l.length > r.length {
                    left.replaceFirst(by: Remove(value: l.length - r.length))
                    right.attemptToRemoveFirst()
                }
            case (let l as Keep, let r as Remove):
                if l.length < r.length {
                    rPrime.chain(Remove(value: l.length))
                    left.attemptToRemoveFirst()
                    right.replaceFirst(by: Remove(value: r.length - l.length))
                } else if l.length == r.length {
                    rPrime.chain(r)
                    left.attemptToRemoveFirst()
                    right.attemptToRemoveFirst()
                } else if l.length > r.length {
                    rPrime.chain(r)
                    left.replaceFirst(by: Keep(value: l.length - r.length))
                    right.attemptToRemoveFirst()
                }
            case (let l as Remove, let r as Keep):
                if l.length < r.length {
                    lPrime.chain(l)
                    left.attemptToRemoveFirst()
                    right.replaceFirst(by: Keep(value: r.length - l.length))
                } else if l.length == r.length {
                    lPrime.chain(l)
                    left.attemptToRemoveFirst()
                    right.attemptToRemoveFirst()
                } else if l.length > r.length {
                    lPrime.chain(Remove(value: r.length))
                    left.replaceFirst(by: Remove(value: l.length - r.length))
                    right.attemptToRemoveFirst()
                }
            default:
                fatalError("Unknown operation combination when trying to harmonize two changesets")
            }
            
            if left.isEmpty && right.isEmpty { finished = true }
        }
        
        return (Changeset(operations: lPrime), Changeset(operations: rPrime))
    }
}


extension Changeset: Codable {
    private enum ChangesetCodingKeys: String, CodingKey {
        case operations
    }
    
    private enum OperationCodingKeys: String, CodingKey {
        case type
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ChangesetCodingKeys.self)
        var operations = try container.nestedUnkeyedContainer(forKey: .operations)
        var decodedOperations = [Operation]()
        while !operations.isAtEnd {
            let operation = try operations.nestedContainer(keyedBy: OperationCodingKeys.self)
            let type = try operation.decode(OperationType.self, forKey: .type)
            switch type {
            case .keep:
                try decodedOperations.chain(Keep(value: operation.decode(Int.self, forKey: .value)))
            case .add:
                try decodedOperations.chain(Add(value: operation.decode(String.self, forKey: .value)))
            case .remove:
                try decodedOperations.chain(Remove(value: operation.decode(Int.self, forKey: .value)))
            }
        }
        self.operations = decodedOperations
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChangesetCodingKeys.self)
        var operationsContainer = container.nestedUnkeyedContainer(forKey: .operations)
        for operation in operations {
            var operationContainer = operationsContainer.nestedContainer(keyedBy: OperationCodingKeys.self)
            switch operation {
            case let op as Keep:
                try operationContainer.encode(OperationType.keep, forKey: .type)
                try operationContainer.encode(op.value, forKey: .value)
            case let op as Add:
                try operationContainer.encode(OperationType.add, forKey: .type)
                try operationContainer.encode(op.value, forKey: .value)
            case let op as Remove:
                try operationContainer.encode(OperationType.remove, forKey: .type)
                try operationContainer.encode(op.value, forKey: .value)
            default:
                fatalError("Trying to encode unknown operation")
            }
        }
    }
}
