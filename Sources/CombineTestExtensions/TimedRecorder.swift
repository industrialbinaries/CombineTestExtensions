//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import Foundation
import XCTest

/// A subscriber which records all values from the attached publisher. Every record
/// has a timestamp from the provided TestScheduler.
public class TimedRecorder<Input, Failure: Error>: Recorder<Input, Failure> {
  public typealias TimedRecord = (time: Int, record: Record)

  /// The recorded records.
  public var timedRecords: [TimedRecord] {
    assert(times.count == records.count, "Internal consistency error.")
    return Array(zip(times, records))
  }

  public override func waitForRecords(
    timeout: TimeInterval = 1,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    scheduler.resume()
    super.waitForRecords(timeout: timeout, file: file, line: line)
  }

  /// Resumes the TestScheduler and waits until the publisher completes.
  /// If the recorder has the required number of records specified, waits for all of them.
  ///
  /// - Parameter timeout: The amount of time within which
  /// the required number of records should be recorded.
  ///
  /// - Returns: Recorded records.
  ///
  public func waitAndCollectTimedRecords(
    timeout: TimeInterval = 1,
    file: StaticString = #file,
    line: UInt = #line
  ) -> [TimedRecord] {
    waitForRecords(timeout: timeout, file: file, line: line)
    return timedRecords
  }

  /// Creates a new TimedRecorder.
  ///
  /// - Parameters:
  ///   - scheduler: TimeSchedule used to determine the current time for of the records.
  ///
  ///   - numberOfRecords: The maximum number of records this recorder
  /// is supposed to record. If `nil`, the recorder records all values until
  /// the completion is received.
  ///
  public init(scheduler: TestScheduler, numberOfRecords: Int? = nil) {
    self.scheduler = scheduler
    super.init(numberOfRecords: numberOfRecords)
  }

  override func append(record: Record) {
    super.append(record: record)
    times.append(scheduler.now)
  }

  private let scheduler: TestScheduler
  private var times: [TestScheduler.SchedulerTimeType] = []
}

extension Publisher {
  /// Creates a new timed recorder subscribed to this publisher.
  public func record(scheduler: TestScheduler, numberOfRecords: Int? = nil) -> TimedRecorder<Output, Failure> {
    let recorder = TimedRecorder<Output, Failure>(scheduler: scheduler, numberOfRecords: numberOfRecords)
    subscribe(recorder)
    return recorder
  }
}

public func XCTAssertEqual<Input: Equatable, Failure: Error>(
  _ records: [TimedRecorder<Input, Failure>.TimedRecord],
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
