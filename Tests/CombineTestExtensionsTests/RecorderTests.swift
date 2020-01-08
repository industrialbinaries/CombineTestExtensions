import Combine
import XCTest

@testable import CombineTestExtensions

final class RecorderTests: XCTestCase {

  func testRecordingExistingValues() {
    let publisher = CurrentValueSubject<Int, Never>.init(5)
    let recorder = publisher.record(numberOfRecords: 1)

    recorder.waitForAllValues()
    XCTAssertRecordedValues(recorder, [5])
  }

  func testWaitingForCompletion() {
    let publisher = PassthroughSubject<Int, Never>()
    let recorder = publisher.record()

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(3) }
    queue.asyncAfter(deadline: .now() + 0.4) { publisher.send(completion: .finished) }

    recorder.waitForAllValues()
    XCTAssertRecordedValues(recorder, [1, 2, 3])
  }

  func testWaitingForAllValues() {
    let publisher = PassthroughSubject<Int, Never>()
    let recorder = publisher.record(numberOfRecords: 3)

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(3) }

    recorder.waitForAllValues()
    XCTAssertRecordedValues(recorder, [1, 2, 3])
  }

  func testPassthroughSubject() {
    let publisher = PassthroughSubject<Int, Never>()
    let recorder = publisher.record(numberOfRecords: 2)

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }

    recorder.waitForAllValues()
    XCTAssertRecordedValues(recorder, [1, 2])
  }

  enum TestError: Error { case mockError }

  func testCompletionWithError() {
    let publisher = PassthroughSubject<Int, TestError>()
    let recorder = publisher.record(numberOfRecords: 3)

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(completion: .failure(.mockError)) }

    recorder.waitForAllValues()
    XCTAssertEqual(recorder.records, [.value(1), .value(2), .completion(.failure(.mockError))])
  }

  func testCompletionWithFinished() {
    let publisher = PassthroughSubject<Int, TestError>()
    let recorder = publisher.record(numberOfRecords: 3)

    let queue = DispatchQueue.global(qos: .default)
    queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
    queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
    queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(completion: .finished) }

    recorder.waitForAllValues()
    XCTAssertEqual(recorder.records, [.value(1), .value(2), .completion(.finished)])
  }
}
