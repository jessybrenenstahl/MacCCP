import XCTest
@testable import MacCCP

final class PlayerTimeFormatterTests: XCTestCase {
    func testFormatsMinutesAndSeconds() {
        XCTAssertEqual(PlayerTimeFormatter.string(from: 0), "00:00")
        XCTAssertEqual(PlayerTimeFormatter.string(from: 65.9), "01:05")
    }

    func testFormatsHoursWhenNeeded() {
        XCTAssertEqual(PlayerTimeFormatter.string(from: 3_725), "1:02:05")
    }

    func testFormatsInvalidTimeAsZero() {
        XCTAssertEqual(PlayerTimeFormatter.string(from: .infinity), "00:00")
        XCTAssertEqual(PlayerTimeFormatter.string(from: -1), "00:00")
    }
}
