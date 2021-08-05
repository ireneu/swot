import XCTest
@testable import Swot

final class SwotMultiByteCharTests: XCTestCase {
    let jsonChangeset = """
        {
            "operations": [
                {
                    "type": "keep",
                    "value": 13
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
        Keep(value: 8),
        Remove(value: 1),
        Keep(value: 2),
        Add(value: " a"),
        Keep(value: 1),
        Add(value: "e "),
        Keep(value: 3),
        Remove(value: 5),
        Add(value: "ty🍴"),
        Keep(value: 1),
        Remove(value: 4)
    ])

    // 👨‍👩‍👧.length == 8
    let baseText = "👨‍👩‍👧qwerty poiu!"
    let firstApply = "👨‍👩‍👧qwertasdfoiu!zxcv"

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

        XCTAssert(retransformedText == "👨‍👩‍👧we are tasty🍴!")

        let chained = try! changeset >>> anotherChangeset
        let chainedApplyText = try! chained.apply(to: baseText)

        XCTAssert(chainedApplyText == "👨‍👩‍👧we are tasty🍴!")
    }

    static var allTests = [
        ("testChangesetApply", testChangesetApply),
        ("testChangesetComposing", testChangesetComposing),
    ]
}
