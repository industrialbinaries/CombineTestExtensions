import Combine
import XCTest

extension Recorder {
  /// Possible types of records.
  public enum Record {
    case value(Input)
    case completion(Subscribers.Completion<Failure>)
  }
}

extension Recorder.Record: Equatable where Input: Equatable, Failure: Equatable { }

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
      if numberOfRecords == records.count {
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
    guard records.count < numberOfRecords else { return }
    let result = waiter.wait(for: [expectation], timeout: timeout)
    if result != .completed {
      func valueFormatter(_ count: Int) -> String {
        "\(count) value" + (count == 1 ? "" : "s")
      }

      XCTFail("""
        Waiting for \(valueFormatter(numberOfRecords)) timed out.
        Received only \(valueFormatter(records.count)).
        """,
        file: file,
        line: line
      )
    }
  }

  public init(numberOfRecords: Int) {
    assert(numberOfRecords > 0, "numberOfRecords must be greater than zero.")
    self.numberOfRecords = numberOfRecords
  }

  private let numberOfRecords: Int

  private let expectation = XCTestExpectation(description: "All values received")
  private let waiter = XCTWaiter()
}

extension Recorder: Subscriber {
  public func receive(subscription: Subscription) {
    subscription.request(.unlimited)
  }

  public func receive(_ input: Input) -> Subscribers.Demand {
    DispatchQueue.main.async { self.records.append(.value(input)) }
    return .unlimited
  }

  public func receive(completion: Subscribers.Completion<Failure>) {
    DispatchQueue.main.async { self.records.append(.completion(completion)) }
  }
}

extension Publisher {
  /// Creates a new recorder subscriber to this publisher.
  public func record(numberOfRecords: Int) -> Recorder<Output, Failure> {
    let recorder = Recorder<Output, Failure>(numberOfRecords: numberOfRecords)
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
  recorder.waitForAllValues(file: file, line: line)

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
