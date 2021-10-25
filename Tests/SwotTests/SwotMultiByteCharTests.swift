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
    let yetAnotherChangeset = Changeset(operations: [
        Remove(value: 11),
        Add(value: " ab"),
        Keep(value: 3),
        Remove(value: 5),
        Add(value: "ty"),
        Keep(value: 5),
        Remove(value: 1)
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

    func testChangesetCombining() {
        let combined = try! anotherChangeset <~> yetAnotherChangeset

        let resa = try! combined.right.apply(to: anotherChangeset.apply(to: firstApply))
        let resb = try! combined.left.apply(to: yetAnotherChangeset.apply(to: firstApply))

        XCTAssert(resa == resb)
    }

    func testChangeSetComposingWithMultiByteChars() {
        let basetext = "A"
        let changeset1 = Changeset(operations: [
            Add(value: "👨‍👩‍👧"),
            Keep(value: 1),
            Add(value: "X")
        ])
        let changeset2 = Changeset(operations: [
            Keep(value: 10),
            Add(value: "YZ")
        ])

        let chained = try! changeset1 >>> changeset2
        let chainedApplyText = try! chained.apply(to: basetext)

        XCTAssert(chainedApplyText == "👨‍👩‍👧AXYZ")
    }

    static var allTests = [
        ("testChangesetApply", testChangesetApply),
        ("testChangesetComposing", testChangesetComposing),
        ("testChangesetCombining", testChangesetCombining),
    ]
}
