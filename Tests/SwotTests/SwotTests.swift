import XCTest
@testable import Swot

final class SwotTests: XCTestCase {
    let jsonChangeset = """
        {
            "operations": [
                {
                    "type": "keep",
                    "value": 5
                },
                {
                    "type": "add",
                    "value": "asdf"
                },
                {
                    "type": "remove",
                    "value": 3
                },
                {
                    "type": "keep",
                    "value": 4
                },
                {
                    "type": "add",
                    "value": "zxcv"
                }
            ]
        }
    """
    let anotherChangeset = Changeset(operations: [
        Remove(value: 1),
        Keep(value: 2),
        Add(value: " a"),
        Keep(value: 1),
        Add(value: "e "),
        Keep(value: 3),
        Remove(value: 5),
        Add(value: "ty"),
        Keep(value: 1),
        Remove(value: 4)
        ])
    let yetAnotherChangeset = Changeset(operations: [
        Remove(value: 3),
        Add(value: " ab"),
        Keep(value: 3),
        Remove(value: 5),
        Add(value: "ty"),
        Keep(value: 5),
        Remove(value: 1)
        ])
    let baseText = "qwerty poiu!"
    let firstApply = "qwertasdfoiu!zxcv"
    
    func testChangesetIsCodable() {
        let decoder = JSONDecoder()
        let changeset = try! decoder.decode(Changeset.self, from: jsonChangeset.data(using: .utf8)!)

        let encoder = JSONEncoder()
        let data = try! encoder.encode(changeset)
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssert(string.components(separatedBy: .whitespacesAndNewlines).joined() == jsonChangeset.components(separatedBy: .whitespacesAndNewlines).joined())
    }
    
    func testChangesetApply() {
        let decoder = JSONDecoder()
        let changeset = try! decoder.decode(Changeset.self, from: jsonChangeset.data(using: .utf8)!)
        
        let result = try! changeset.apply(to: baseText)
        
        XCTAssert(result == firstApply)
    }
    
    func testChangesetComposing() {
        let decoder = JSONDecoder()
        let changeset = try! decoder.decode(Changeset.self, from: jsonChangeset.data(using: .utf8)!)
        
        let transformedText = try! changeset.apply(to: baseText)
        let retransformedText = try! anotherChangeset.apply(to: transformedText)
        
        XCTAssert(retransformedText == "we are tasty!")
        
        let chained = try! changeset >>> anotherChangeset
        let chainedApplyText = try! chained.apply(to: baseText)
        
        XCTAssert(chainedApplyText == "we are tasty!")
    }
    
    func testChangesetCombining() {
        let combined = try! anotherChangeset <~> yetAnotherChangeset
        
        let resa = try! combined.right.apply(to: anotherChangeset.apply(to: firstApply))
        let resb = try! combined.left.apply(to: yetAnotherChangeset.apply(to: firstApply))
        
        XCTAssert(resa == resb)
    }

    static var allTests = [
        ("testChangesetIsCodable", testChangesetIsCodable),
        ("testChangesetApply", testChangesetApply),
        ("testChangesetComposing", testChangesetComposing),
        ("testChangesetCombining", testChangesetCombining),
    ]
}
