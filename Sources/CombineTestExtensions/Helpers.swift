//
//  CombineTestExtensions
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Foundation

/// Pretty-prints the elements of two arrays to the console and highlights
/// the elements which are not equal.
func printDiff<T1, T2>(_ c1: [T1], _ c2: [T2]) {
  for idx in 0 ..< max(c1.count, c2.count) {
    let left = c1[description: idx]
    let right = c2[description: idx]

    print("""
    [\(idx)] \(left != right ? "❌" : "")
      lhs: \(left)
      rhs: \(right)

    """)
  }
}

private extension Array {
  subscript(description index: Index) -> String {
    if indices.contains(index) {
      return String(describing: self[index])
    } else {
      return "-"
    }
  }
}
