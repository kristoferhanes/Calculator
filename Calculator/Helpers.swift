//
//  Helpers.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 07.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

func zip<T,U>(x: T?, _ y: U?) -> (T, U)? {
  return x.flatMap { x in y.map { y in (x, y) } }
}

extension String {
  func removeDecimalZero() -> String {
    guard characters.count > 1 else { return self }
    let end = startIndex.advancedBy(characters.count-2)
    return substringFromIndex(end) == ".0" ? self[startIndex..<end] : self
  }
}
