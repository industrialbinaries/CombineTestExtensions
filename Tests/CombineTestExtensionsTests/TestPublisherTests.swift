//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import CombineTestExtensions

import Combine
import XCTest

class TestPublisherTests: XCTestCase {
  struct MockError: Error {}
  struct MockError2: Error {}

  var scheduler: TestScheduler!

  override func setUp() {
    super.setUp()
    scheduler = TestScheduler()
  }

  func testPublisher() {
    let publisher: TestPublisher<Int, Never> = .init(scheduler, [
      (10, .value(100)),
      (50, .value(500)),
      (20, .value(200)),
      (70, .completion(.finished)),
      (60, .value(600)),
    ])

    let records = publisher
      .record(scheduler: scheduler)
      .waitAndCollectTimedRecords()

    XCTAssertEqual(records, [
      (10, .value(100)),
      (20, .value(200)),
      (50, .value(500)),
      (60, .value(600)),
      (70, .completion(.finished)),
    ])
  }

  func testPublisherWithError() {
    let publisher: TestPublisher<Int, Error> = .init(scheduler, [
      (10, .value(100)),
      (50, .completion(.failure(MockError()))),
    ])

    let records = publisher
      .record(scheduler: scheduler)
      .waitAndCollectTimedRecords()

    XCTAssertEqual(records, [
      (10, .value(100)),
      (50, .completion(.failure(MockError()))),
    ])
  }
}
