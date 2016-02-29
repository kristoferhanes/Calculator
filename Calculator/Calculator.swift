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
      guard let exprStr = expression else { return }
      expr = Expression(parse: exprStr)
    }
  }

  var variables: [String:Double]

  private var expr: Expression?

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
    return expr?.valueWith(variables)
  }

}
