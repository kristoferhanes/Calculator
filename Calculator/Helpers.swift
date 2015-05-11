//
//  Helpers.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 07.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

func flatMap<A,B,C>(a: A?, b: B?, f: (A,B)->C?) -> C? {
  return flatMap(a) { a in flatMap(b) { b in f(a, b) } }
}

func doubleFromString(s: String) -> Double? {
  return NSNumberFormatter().numberFromString(s)?.doubleValue
}

func removeDecimalZeroFrom(s: String) -> String {
  if count(s) < 2 { return s }
  var result = Array(s)
  let lastTwo = result.endIndex-2...result.endIndex-1
  let end = result[lastTwo]
  if end.first! == "." && end.last! == "0" {
    result.removeRange(lastTwo)
  }
  return String(result)
}

