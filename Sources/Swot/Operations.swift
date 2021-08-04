/// Changeset operation
public protocol ChangesetOperation: Codable {
    /// Operation length
    var length: Int { get }
}


enum OperationType: String, Codable {
    case keep
    case add
    case remove
}


/// Changeset operation that keeps characters from document
public struct Keep: ChangesetOperation {
    /// Kept characters
    public let value: Int
    public var length: Int { return value }

    public init(value: Int) {
        self.value = value
    }
}


/// Changeset operation that adds characters to document
public struct Add: ChangesetOperation {
    /// Added characters
    public let value: String
    public var length: Int { return value.utf16.count }

    public init(value: String) {
        self.value = value
    }
}


/// Changeset operation that removes characters from document
public struct Remove: ChangesetOperation {
    /// Removed characters
    public let value: Int
    public var length: Int { return value }

    public init(value: Int) {
        self.value = value
    }
}
