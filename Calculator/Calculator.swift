//
//  Calculator.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2016 02 27.
//  Copyright © 2016 Kristofer Hanes. All rights reserved.
//

import Foundation

struct Calculator {

  var expression: String? {
    didSet {
      if let exprStr = expression {
        expr = Expression(parse: exprStr)
      } else {
        expr = nil
      }
    }
  }

  var variables: [String:Double]

  fileprivate var expr: Expression?

}

extension Calculator {

  init() {
    expr = nil
    variables = [:]
  }

  mutating func clear() {
    expression = nil
  }

  mutating func clearAll() {
    expression = nil
    variables = [:]
  }

  var value: Double? {
    return expr?.evaluated(with: variables)
  }
  
}
