import Combine
import Foundation

struct TestPublisher<Output, Failure: Error>: Publisher {

  enum Event {
    case value(Output)
    case completion(Subscribers.Completion<Failure>)
  }

  struct Record {
    let time: TestScheduler.SchedulerTimeType
    let value: Event
  }

  let scheduler: TestScheduler

  init(values: [Record], scheduler: TestScheduler) {
    self.values = values
    self.scheduler = scheduler
  }

  let values: [Record]

  func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
    subscriber.receive(subscription: TestSubscription(subscriber: subscriber, values: values, scheduler: scheduler))
  }

  fileprivate class TestSubscription<S: Subscriber>: Subscription where Failure == S.Failure, Output == S.Input {

    let s: S
    let values: [Record]
    let scheduler: TestScheduler

    init(subscriber: S, values: [Record], scheduler: TestScheduler) {
      self.s = subscriber
      self.values = values
      self.scheduler = scheduler
    }

    func request(_ demand: Subscribers.Demand) {
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

    }

  }
}

//fileprivate final class TestablePublisherSubscription<Sink: Subscriber>: Subscription {
//
//    private let linkedList = LinkedList<Int>.empty
//    private var queue: SinkQueue<Sink>?
//    private var cancellables = [AnyCancellable]()
//
//    init(sink: Sink, testScheduler: TestScheduler, behavior: TestablePublisherBehavior, testSequence: TestSequence<Sink.Input, Sink.Failure>) {
//
//        let queue = SinkQueue(sink: sink)
//
//        testSequence.forEach { (time, signal) in
//
//            guard behavior == .relative || testScheduler.now <= time else { return }
//            let due = behavior == .relative ? testScheduler.now + time : time
//
//            switch signal {
//            case .subscription:
//                assertionFailure("Illegal input. A `.subscription` event scheduled at \(time) will be ignored. Only a Subscriber can initiate a Subscription.")
//                break
//            case .input(let value):
//                let cancellable = testScheduler.schedule(after: due, interval: 0) {
//                    _ = queue.enqueue(value)
//                }
//                cancellables.append(AnyCancellable { cancellable.cancel() })
//            case .completion(let completion):
//                let cancellable = testScheduler.schedule(after: due, interval: 0) {
//                    queue.expediteCompletion(completion)
//                }
//                cancellables.append(AnyCancellable { cancellable.cancel() })
//            }
//        }
//
//        self.queue = queue
//    }
//
//    deinit {
//        cancellables.forEach { $0.cancel() }
//    }
//
//    func request(_ demand: Subscribers.Demand) {
//        _ = queue?.requestDemand(demand)
//    }
//
//    func cancel() {
//        queue = nil
//    }
//}
//
