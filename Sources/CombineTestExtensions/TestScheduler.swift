import Combine
import Foundation

public class TestScheduler: Scheduler {

  public typealias SchedulerTimeType = Int
  public typealias SchedulerOptions = Never

  public func resume() {
    var tasks = self.tasks.sorted { $0.time < $1.time }

    while !tasks.isEmpty {
      autoreleasepool {
        let task = tasks.removeFirst()
        currentTime = task.time
        task.action()
      }
    }
  }

  private var tasks: [Task] = []

  var currentTime = 0

  public var now: Int { currentTime }

  public var minimumTolerance: Int { 1 }

  public func schedule(options: Never?, _ action: @escaping () -> Void) {
    schedule(after: currentTime, tolerance: 0, options: options, action)
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
}

extension TestScheduler {

  struct Task: Hashable {
    let time: SchedulerTimeType
    let action: () -> Void

    private let id: UUID = .init()

    static func == (lhs: TestScheduler.Task, rhs: TestScheduler.Task) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }
}

extension Int: SchedulerTimeIntervalConvertible {
  public static func seconds(_ s: Int) -> Int {
      return .init(s)
  }

  public static func seconds(_ s: Double) -> Int {
      return .init(Int(s + 0.5))
  }

  public static func milliseconds(_ ms: Int) -> Int {
      .seconds(Double(ms) / 1e+3)
  }

  public static func microseconds(_ us: Int) -> Int {
      .seconds(Double(us) / 1e+6)
  }

  public static func nanoseconds(_ ns: Int) -> Int {
      .seconds(Double(ns) / 1e+9)
  }
}
