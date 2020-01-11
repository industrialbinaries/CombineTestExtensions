//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import CombineTestExtensions

import XCTest

final class TestSchedulerTests: XCTestCase {
  func testSchedulingWorksCorrectly() {
    let scheduler = TestScheduler()

    var result: [Int] = []

    scheduler.schedule(after: 100) { result.append(4) }
    scheduler.schedule(after: 70) { result.append(3) }

    scheduler.schedule(after: 50) {
      scheduler.schedule(after: 60) { result.append(2) }
    }

    scheduler.schedule { result.append(1) }

    scheduler.resume()

    XCTAssertEqual(result, [1, 2, 3, 4])
  }
}
