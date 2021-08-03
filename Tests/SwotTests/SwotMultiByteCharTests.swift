import XCTest
@testable import Swot

final class SwotMultiByteCharTests: XCTestCase {
    let jsonChangeset = """
        {
            "operations": [
                {
                    "type": "keep",
                    "value": 12
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

    // 👨‍👩‍👧.length == 8
    let baseText = "👨‍👩‍👧qerty poiu!"
    let firstApply = "👨‍👩‍👧qertasdfoiu!zxcv"

    func testChangesetApply() {
        let decoder = JSONDecoder()
        let changeset = try! decoder.decode(Changeset.self, from: jsonChangeset.data(using: .utf8)!)

        let result = try! changeset.apply(to: baseText)

        XCTAssert(result == firstApply)
    }

    static var allTests = [
        ("testChangesetApply", testChangesetApply),
    ]
}
