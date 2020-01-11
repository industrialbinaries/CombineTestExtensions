# Combine Test Extensions 

[![Build Status](https://github.com/industrialbinaries/CombineTestExtensions/workflows/Tests%20iOS/badge.svg)](https://github.com/industrialbinaries/CombineTestExtensions)
[![SPM Compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
![Platforms: macOS+iOS+tvOS ](https://img.shields.io/badge/platforms-macOS%20iOS%20tvOS-brightgreen.svg?style=flat)
[![Twitter](https://img.shields.io/badge/twitter-@i_binaries-blue.svg?style=flat)](https://twitter.com/i_binaries)

---

A set of tools making writing tests for [Apple's Combine](https://developer.apple.com/documentation/combine) framework easy. Inspired by [RxTest and RxBlocking](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/UnitTests.md).

---

## `Recorder`

A `Subscriber` implementation which records all values from the attached publisher.

```swift
import CombineTestExtensions

let publisher = PassthroughSubject<Int, TestError>()
let recorder = publisher.record()

let queue = DispatchQueue.global(qos: .default)
queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(completion: .finished) }

let records = recorder.waitAndCollectRecords()

XCTAssertEqual(records, [.value(1), .value(2), .completion(.finished)])
```

You can also specify the number of values you want to record. This is handy when the recorded publisher never completes.

```swift
import CombineTestExtensions

let publisher = PassthroughSubject<Int, Never>()
let recorder = publisher.record(numberOfRecords: 3)

let queue = DispatchQueue.global(qos: .default)
queue.asyncAfter(deadline: .now() + 0.1) { publisher.send(1) }
queue.asyncAfter(deadline: .now() + 0.2) { publisher.send(2) }
queue.asyncAfter(deadline: .now() + 0.3) { publisher.send(3) }
queue.asyncAfter(deadline: .now() + 0.4) { publisher.send(4) }

let records = recorder.waitAndCollectRecords()

XCTAssertEqual(records, [.value(1), .value(2), .value(3)])
```

## `TimedRecorder`

`TimedRecorder` is a subclass of `Recorder` expanding its functionality by adding timestamps to recorded events. It's not that useful by itself but it really shines in combination with `TestPublisher`. To create a new `TimerRecorder` instance, you have to provide it with a `TestScheduler`:

```swift
let scheduler = TestScheduler()
let timedRecorder = some_Publisher.record(scheduler: scheduler)
```

## `TestScheduler`

A `Scheduler` implementation for using in tests. It uses `Int` for its time type. The scheduler is inactive until `resume()` is called. It doesn't make much sense to use it alone. It's main purpose is to be used with `TestPublisher` and `TimedRecorder`.

This example explains how `TestScheduler` works:
```swift
import CombineTestExtensions

let scheduler = TestScheduler()

var result: [Int] = []

scheduler.schedule(after: 100) { result.append(3) }
scheduler.schedule(after: 50) { result.append(2) }
scheduler.schedule { result.append(1) }

scheduler.resume()

XCTAssertEqual(result, [1, 2, 3])
```

## `TestPublisher`

`TestPublisher` allows you to schedule events to be sent at specific "virtual time" timestamps. It's the perfect match for `TimedRecorder`:

```swift
import CombineTestExtensions

let scheduler = TestScheduler()

let publisher: TestPublisher<Int, Never> = .init(scheduler, [
    (40, .completion(.finished)),
    (30, .value(300)),
    (20, .value(200)),
    (10, .value(100)),
])

let toString = publisher.map(String.init)

let records = toString
    .record(scheduler: scheduler)
    .waitAndCollectTimedRecords()

XCTAssertEqual(records, [
    (10, .value("100")),
    (20, .value("200")),
    (30, .value("300")),
    (40, .completion(.finished)),
])
```

---

## Alternatives

If you need more advanced test tools for `Combine`, check out [EntwineTest](https://github.com/tcldr/Entwine/blob/master/Assets/EntwineTest/README.md). It's almost a 1:1 re-implementation of `RxTest` with support for Combine-specific features like backpressure.

## License and Credits

Created by [Industrial Binaries](https://industrial-binaries.co).

**CombineTestExtensions** is released under the MIT license. See [LICENSE](https://github.com/industrialbinaries/CombineTestExtensions/blob/master/LICENSE) for details.
