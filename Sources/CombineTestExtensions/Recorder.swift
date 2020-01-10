//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import XCTest

// MARK: - Recorder

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
  /// The recorded records.
  public var records: [Record] = [] {
    didSet {
      if shouldStopRecording {
        expectation.fulfill()
      }
    }
  }

  /// Pauses the execution of the current tests and waits until the publisher completes.
  /// If the recorder has the required number of records specified, waits for all of them.
  ///
  /// - Parameter timeout: The amount of time within which
  /// the required number of records should be recorded.
  ///
  public func waitForRecords(
    timeout: TimeInterval = 1,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    defer { subscription?.cancel() }

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
        line: line)
      } else {
        XCTFail("""
        Waiting for the subscription to complete timed out.
        Received only \(valueFormatter(records.count)).
        """,
        file: file,
        line: line)
      }
    }
  }

  /// Pauses the execution of the current tests and waits until the publisher completes.
  /// If the recorder has the required number of records specified, waits for all of them.
  ///
  /// - Parameter timeout: The amount of time within which
  /// the required number of records should be recorded.
  ///
  /// - Returns: Recorded records.
  ///
  public func waitAndCollectRecords(
    timeout: TimeInterval = 1,
    file: StaticString = #file,
    line: UInt = #line
  ) -> [Record] {
    waitForRecords(timeout: timeout, file: file, line: line)
    return records
  }

  /// Creates a new Recorder.
  ///
  /// - Parameter numberOfRecords: The maximum number of records this recorder
  /// is supposed to record. If `nil`, the recorder records all values until
  /// the completion is received.
  ///
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

  private var subscription: Subscription?
}

extension Recorder {
  private var shouldStopRecording: Bool {
    if let numberOfRecords = self.numberOfRecords {
      return numberOfRecords == records.count
    }

    if case .completion = records.last { return true }

    return false
  }
}

extension Recorder: Subscriber {
  public func receive(subscription: Subscription) {
    assert(self.subscription == nil)
    self.subscription = subscription
    subscription.request(.unlimited)
  }

  public func receive(_ input: Input) -> Subscribers.Demand {
    let action = { self.append(record: .value(input)) }
    if Thread.current.isMainThread {
      action()
    } else {
      DispatchQueue.main.async(execute: action)
    }
    return .none
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

extension Publisher {
  /// Creates a new recorder subscribed to this publisher.
  public func record(numberOfRecords: Int? = nil) -> Recorder<Output, Failure> {
    let recorder = Recorder<Output, Failure>(numberOfRecords: numberOfRecords)
    subscribe(recorder)
    return recorder
  }
}

public func XCTAssertRecordedValues<Input: Equatable, Failure: Error>(
  _ records: [Recorder<Input, Failure>.Record],
  _ expectedValues: [Input],
  file: StaticString = #file,
  line: UInt = #line
) {
  // Get only the values, ignore othe records
  let values = records.compactMap { record -> Input? in
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

// MARK: - Helpers

internal func != <Input: Equatable, Failure: Error>(
  lhs: Recorder<Input, Failure>.Record,
  rhs: Recorder<Input, Failure>.Record
) -> Bool {
  !(lhs == rhs)
}

internal func == <Input: Equatable, Failure: Error>(
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
