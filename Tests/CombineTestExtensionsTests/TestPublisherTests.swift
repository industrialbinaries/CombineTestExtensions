//
//  TestPublisherTests.swift
//  CombineTestExtensionsTests
//
//  Created by Vojta on 08/01/2020.
//

@testable import CombineTestExtensions

import XCTest
import Combine

class TestPublisherTests: XCTestCase {

  struct MockError: Error { }
  struct MockError2: Error { }

  var scheduler: TestScheduler!

  override func setUp() {
    super.setUp()
    scheduler = TestScheduler()
  }

  func testPublisher() {
    let publisher: TestPublisher<Int, Never> = .init(
      values: [
        .init(time: 10, value: .value(100)),
        .init(time: 50, value: .value(500)),
        .init(time: 20, value: .value(200)),
        .init(time: 70, value: .completion(.finished)),
        .init(time: 60, value: .value(600)),
      ],
      scheduler: scheduler
    )

    let records = publisher
      .record(scheduler: scheduler)
      .waitForRecords()

    XCTAssertEqual(records, [
      (10, .value(100)),
      (20, .value(200)),
      (50, .value(500)),
      (60, .value(600)),
      (70, .completion(.finished)),
    ])
  }

  func testPublisherWithError() {
    let publisher: TestPublisher<Int, Error> = .init(
      values: [
        .init(time: 10, value: .value(100)),
        .init(time: 50, value: .completion(.failure(MockError()))),
      ],
      scheduler: scheduler
    )

    let records = publisher
      .record(scheduler: scheduler)
      .waitForRecords()

    XCTAssertEqual(records, [
      (10, .value(100)),
      (50, .completion(.failure(MockError()))),
    ])
  }
}
