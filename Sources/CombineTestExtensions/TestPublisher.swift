//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import Foundation

/// A `Publisher` implementation allowing sending events using TestPublisher
/// at predefined time.
public struct TestPublisher<Output, Failure: Error>: Publisher {
  public enum Value {
    case value(Output)
    case completion(Subscribers.Completion<Failure>)
  }

  public struct Event {
    public let time: TestScheduler.SchedulerTimeType
    public let value: Value
  }

  public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    subscriber.receive(subscription: Subscription_(subscriber: subscriber, values: values, scheduler: scheduler))
  }

  /// Creates a new TestPublisher.
  ///
  /// - Parameters:
  ///   - scheduler: Test scheduler to be used for sending the events.
  ///   - events: The events to be sent by this publisher.
  ///
  public init(_ scheduler: TestScheduler, _ events: [(time: Int, event: Value)]) {
    self.scheduler = scheduler
    values = events.map(Event.init)
  }

  let values: [Event]
  let scheduler: TestScheduler
}

extension TestPublisher {
  private class Subscription_<S: Subscriber>: Subscription
    where Failure == S.Failure, Output == S.Input {
    let s: S
    let values: [Event]
    let scheduler: TestScheduler

    init(subscriber: S, values: [Event], scheduler: TestScheduler) {
      s = subscriber
      self.values = values
      self.scheduler = scheduler
    }

    func request(_ demand: Subscribers.Demand) {
      // TODO: Handle demand?
      values
        .sorted { $0.time < $1.time }
        .forEach { record in
          scheduler.schedule(after: record.time, tolerance: 0, options: nil) {
            switch record.value {
            case let .value(value):
              _ = self.s.receive(value)

            case let .completion(completion):
              self.s.receive(completion: completion)
            }
          }
        }
    }

    func cancel() {
      // TODO: ?
    }
  }
}
