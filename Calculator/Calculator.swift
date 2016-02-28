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
      expr = expression.flatMap(Expr.init)
    }
  }
  private var expr: Expr?
  private var env: [String:Double]
}

extension Calculator {

  init() {
    expression = nil
    expr = nil
    env = [:]
  }

  mutating func updateVariable(variable: String, withValue value: Double) {
    env[variable] = value
  }

  mutating func deleteVariable(variable: String) {
    env[variable] = nil
  }

  var value: Double? {
    return expr?.valueWith(env)
  }

}