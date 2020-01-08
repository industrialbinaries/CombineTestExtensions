import Combine
import XCTest

extension Recorder {
  /// Possible types of records.
  public enum Record {
    case value(Input)
    case completion(Subscribers.Completion<Failure>)
  }
}

extension Recorder.Record: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .value(inputValue):
      return "\(inputValue)"
    case let .completion(completionValue):
      return "\(completionValue)"
    }
  }
}

/// A subscriber which records all values from the attached publisher.
public class Recorder<Input, Failure: Error> {

  public var records: [Record] = [] {
    didSet {
      if
        let numberOfRecords = self.numberOfRecords,
        numberOfRecords == records.count
      {
        expectation.fulfill()

      } else if case .completion = records.last {
        expectation.fulfill()
      }
    }
  }

  /// Pauses the execution of the current tests and waits,
  /// until the required number of values is recorded.
  ///
  /// - Parameter timeout: The amount of time within which
  /// the required number of records should be recorded.

  public func waitForAllValues(
    timeout: TimeInterval = 1,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let result = waiter.wait(for: [expectation], timeout: timeout)
    if result != .completed {
      func valueFormatter(_ count: Int) -> String {
        "\(count) value" + (count == 1 ? "" : "s")
      }

      if let numberOfRecords = self.numberOfRecords {
        XCTFail("""
          Waiting for \(valueFormatter(numberOfRecords)) timed out.
          Received only \(valueFormatter(records.count)).
          """,
          file: file,
          line: line
        )
      } else {
        XCTFail("""
          Waiting for the subscription to complete timed out.
          Received only \(valueFormatter(records.count)).
          """,
          file: file,
          line: line
        )
      }
    }
  }

  /// Creates a new Recorder.
  ///
  /// - Parameter numberOfRecords: The maximum number of records this recorder
  /// is supposed to record. If `nil`, the recorder records all values until
  /// the completion is received.

  public init(numberOfRecords: Int? = 0) {
    if let numberOfRecords = numberOfRecords {
      assert(numberOfRecords > 0, "numberOfRecords must be greater than zero.")
    }
    self.numberOfRecords = numberOfRecords
  }

  internal func append(record: Record) {
    records.append(record)
  }

  private let numberOfRecords: Int?

  private let expectation = XCTestExpectation(description: "All values received")
  private let waiter = XCTWaiter()
}

extension Recorder: Subscriber {
  public func receive(subscription: Subscription) {
    subscription.request(.unlimited)
  }

  public func receive(_ input: Input) -> Subscribers.Demand {
    let action = { self.append(record: .value(input)) }
    if Thread.current.isMainThread {
      action()
    } else {
      DispatchQueue.main.async(execute: action)
    }
    return .unlimited
  }

  public func receive(completion: Subscribers.Completion<Failure>) {
    let action = { self.append(record: .completion(completion)) }
    if Thread.current.isMainThread {
      action()
    } else {
      DispatchQueue.main.async(execute: action)
    }
  }
}

public class TimeRecorder<Input, Failure: Error>: Recorder<Input, Failure> {

  public typealias TimeRecord = (time: Int, record: Record)

  public var timeRecords: [TimeRecord] {
    Array(zip(times, records))
  }

  public func waitForRecords(timeout: TimeInterval = 1) -> [TimeRecord] {
    scheduler.resume()
    super.waitForAllValues(timeout: timeout)
    return timeRecords
  }

  public init(scheduler: TestScheduler, numberOfRecords: Int? = nil) {
    self.scheduler = scheduler
    super.init(numberOfRecords: numberOfRecords)
  }

  private let scheduler: TestScheduler

  private var times: [TestScheduler.SchedulerTimeType] = []

  override func append(record: Record) {
    super.append(record: record)
    times.append(scheduler.currentTime)
  }
}

extension Publisher {
  /// Creates a new recorder subscriber to this publisher.
  public func record(numberOfRecords: Int? = nil) -> Recorder<Output, Failure> {
    let recorder = Recorder<Output, Failure>(numberOfRecords: numberOfRecords)
    subscribe(recorder)
    return recorder
  }

  /// Creates a new recorder subscriber to this publisher.
  public func record(scheduler: TestScheduler, numberOfRecords: Int? = nil) -> TimeRecorder<Output, Failure> {
    let recorder = TimeRecorder<Output, Failure>(scheduler: scheduler, numberOfRecords: numberOfRecords)
    subscribe(recorder)
    return recorder
  }
}

public func XCTAssertRecordedValues<Input: Equatable, Failure: Error>(
  _ recorder: Recorder<Input, Failure>,
  _ expectedValues: [Input],
  file: StaticString = #file,
  line: UInt = #line
) {
  // Get only the values, ignore othe records
  let values = recorder.records.compactMap { record -> Input? in
    if case let .value(inputValue) = record {
      return inputValue
    } else {
      return nil
    }
  }
  XCTAssertEqual(values, expectedValues, file: file, line: line)
}

public func XCTAssertEqual<Input: Equatable, Failure: Error>(
  _ records: [Recorder<Input, Failure>.Record],
  _ expectedValues: [Recorder<Input, Failure>.Record],
  file: StaticString = #file,
  line: UInt = #line
) {
  func fail() {
    XCTFail("Records not equal. See the console output for more info.", file: file, line: line)
  }

  guard records.count == expectedValues.count else {
    fail(); return
  }

  zip(records, expectedValues).forEach {
    if $0 != $1 {
      fail(); return
    }
  }
}

public func XCTAssertEqual<Input: Equatable, Failure: Error>(
  _ records: [TimeRecorder<Input, Failure>.TimeRecord],
  _ expectedValues: [(time: Int, record: Recorder<Input, Failure>.Record)],
  file: StaticString = #file,
  line: UInt = #line
) {
  func fail() {
    XCTFail("Records not equal. See the console output for more info.", file: file, line: line)
    printDiff(records, expectedValues)
  }

  guard records.count == expectedValues.count else {
    fail(); return
  }

  zip(records, expectedValues).forEach {
    if $0.0 != $1.0 || $0.1 != $1.1 {
      fail(); return
    }
  }
}

private func != <Input: Equatable, Failure: Error>(
  lhs: Recorder<Input, Failure>.Record,
  rhs: Recorder<Input, Failure>.Record
) -> Bool {
  !(lhs == rhs)
}

private func == <Input: Equatable, Failure: Error>(
  lhs: Recorder<Input, Failure>.Record,
  rhs: Recorder<Input, Failure>.Record
) -> Bool {
  switch (lhs, rhs) {
  case let (.value(lValue), .value(rValue)):
    return lValue == rValue

  case (.completion(.finished), .completion(.finished)):
    return true

  case let (.completion(.failure(lError)), .completion(.failure(rError))):
    return lError.localizedDescription == rError.localizedDescription

  default:
    return false
  }
}

private func printDiff<T1, T2>(_ c1: [T1], _ c2: [T2]) {
  for idx in 0..<max(c1.count, c2.count) {
    print("""
    [\(idx)]
      lhs: \(c1[description: idx])
      rhs: \(c2[description: idx])

    """)
  }
}

private extension Array {
  subscript(description index: Index) -> String {
    if self.indices.contains(index) {
      return String(describing: self[index])
    } else {
      return "-"
    }
  }
}
