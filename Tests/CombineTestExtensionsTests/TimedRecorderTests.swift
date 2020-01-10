//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import XCTest

@testable import CombineTestExtensions

final class TimedRecorderTests: XCTestCase {
  func testRecordingWithTimestamps() {
    let scheduler = TestScheduler()
    let publisher = PassthroughSubject<String, Never>()
    let recorder = publisher.record(scheduler: scheduler)

    scheduler.now = 100
    publisher.send("A")

    scheduler.now = 110
    publisher.send("B")

    scheduler.now = 120
    publisher.send("C")

    let result = recorder.timedRecords

    XCTAssertEqual(result, [
      (100, .value("A")),
      (110, .value("B")),
      (120, .value("C")),
    ])
  }
}
