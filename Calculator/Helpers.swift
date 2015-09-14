//
//  Helpers.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 07.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

func zip<T,U>(x: T?, _ y: U?) -> (T,U)? {
  return x.flatMap { x in y.map { y in (x, y) } }
}

extension String {

  func removeDecimalZero() -> String {
    if self.characters.count < 2 { return self }
    let end = startIndex.advancedBy(self.characters.count-2)
    return substringFromIndex(end) == ".0" ? self[startIndex..<end] : self
  }

}

extension Double {

  init?(string: String) {
    let value = NSNumberFormatter().numberFromString(string)?.doubleValue
    if value == nil { return nil }
    self.init(value!)
  }
  
}