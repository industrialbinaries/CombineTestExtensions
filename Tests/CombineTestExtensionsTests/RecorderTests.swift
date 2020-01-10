//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import XCTest

@testable import CombineTestExtensions

final class RecorderTests: XCTestCase {
  enum TestError: Error { case mockError }

  func testRecordingDefinedNumberOfValues() {
    let publisher = PassthroughSubject<Int, Never>()
    let recorder = publisher.record(numberOfRecords: 3)

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(3) }
    queue.asyncAfter(deadline: .now() + 0.4) { publisher.send(4) }

    let records = recorder.waitAndCollectRecords()

    XCTAssertRecordedValues(records, [1, 2, 3])
  }

  func testRecordingWithError() {
    let publisher = PassthroughSubject<Int, TestError>()
    let recorder = publisher.record()

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(completion: .failure(.mockError)) }

    let records = recorder.waitAndCollectRecords()

    XCTAssertEqual(records, [.value(1), .value(2), .completion(.failure(.mockError))])
  }

  func testRecordingWithFinished() {
    let publisher = PassthroughSubject<Int, TestError>()
    let recorder = publisher.record()

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(completion: .finished) }

    let records = recorder.waitAndCollectRecords()

    XCTAssertEqual(records, [.value(1), .value(2), .completion(.finished)])
  }

  func testRecordingExistingValues() {
    let publisher = CurrentValueSubject<Int, Never>.init(5)
    let recorder = publisher.record(numberOfRecords: 1)

    let records = recorder.waitAndCollectRecords()

    XCTAssertRecordedValues(records, [5])
  }
}
