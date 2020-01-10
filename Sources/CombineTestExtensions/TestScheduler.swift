//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import Foundation

/// A `Scheduler` implementation for using in tests. It uses `Int` for its
/// time type.
///
/// The scheduler is inactive until `resume()` is called.
///
public class TestScheduler: Scheduler {
  public typealias SchedulerOptions = Never

  public var now: Int = 0
  public var minimumTolerance: Int = 0

  /// Starts the scheduler. All scheduled actions are performed immediately and synchronously.
  public func resume() {
    while !tasks.isEmpty {
      // This sort is stable https://forums.swift.org/t/is-sort-stable-in-swift-5/21297
      tasks.sort { $0.time < $1.time }

      let task = tasks.removeFirst()
      now = task.time
      task.action()
    }
  }

  public func schedule(options: Never?, _ action: @escaping () -> Void) {
    schedule(after: now, tolerance: 0, options: options, action)
  }

  public func schedule(after date: Int, tolerance: Int, options: Never?, _ action: @escaping () -> Void) {
    let task = Task(time: date, action: action)
    tasks.append(task)
  }

  public func schedule(
    after date: Int,
    interval: Int,
    tolerance: Int,
    options: Never?,
    _ action: @escaping () -> Void
  ) -> Cancellable {
    fatalError("Not implemented yet.")
  }

  /// Creates a new TestScheduler.
  public init() {}

  private var tasks: [Task] = []
}

extension TestScheduler {
  fileprivate struct Task: Hashable {
    let time: Int
    let action: () -> Void

    private let id: UUID = .init()
  }
}

extension TestScheduler.Task {
  static func == (lhs: TestScheduler.Task, rhs: TestScheduler.Task) -> Bool { lhs.id == rhs.id }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Int: SchedulerTimeIntervalConvertible {
  public static func seconds(_ s: Int) -> Int {
    return .init(s)
  }

  public static func seconds(_ s: Double) -> Int {
    fatalError("Not supported yet.")
  }

  public static func milliseconds(_ ms: Int) -> Int {
    fatalError("Not supported yet.")
  }

  public static func microseconds(_ us: Int) -> Int {
    fatalError("Not supported yet.")
  }

  public static func nanoseconds(_ ns: Int) -> Int {
    fatalError("Not supported yet.")
  }
}
