import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwotTests.allTests),
        testCase(SwotMultiByteCharTests.allTests),
    ]
}
#endif
