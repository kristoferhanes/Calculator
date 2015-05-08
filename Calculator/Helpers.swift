//
//  Helpers.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 07.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

func flatMap<T,U>(x: T?, y: T?, f: (T,T)->U?) -> U? {
  return flatMap(x) { x in flatMap(y) { y in f(x, y) } }
}

func doubleFromString(s: String) -> Double? {
  return NSNumberFormatter().numberFromString(s)?.doubleValue
}