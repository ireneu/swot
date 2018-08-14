
protocol Operation: Codable {
    var length: Int { get }
}


enum OperationType: String, Codable {
    case keep
    case add
    case remove
}


struct Keep: Operation {
    let value: Int
    var length: Int { return value }
}


struct Add: Operation {
    let value: String
    var length: Int { return value.count }
}


struct Remove: Operation {
    let value: Int
    var length: Int { return value }
}
