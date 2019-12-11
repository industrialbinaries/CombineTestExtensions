//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(CombineTestExtensionsTests.allTests),
    ]
  }
#endif
