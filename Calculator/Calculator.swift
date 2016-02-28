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
      expr = expression.flatMap(Expression.init)
    }
  }
  private var expr: Expression?
  private var variableValues: [String:Double]
}

extension Calculator {

  init() {
    expression = nil
    expr = nil
    variableValues = [:]
  }

  mutating func updateVariable(variable: String, withValue value: Double) {
    variableValues[variable] = value
  }

  mutating func deleteVariable(variable: String) {
    variableValues[variable] = nil
  }

  mutating func deleteAllVariables() {
    variableValues = [:]
  }

  mutating func mergeVariables(variables: [String:Double]) {
    for (variable, value) in variables {
      variableValues[variable] = value
    }
  }

  mutating func clear() {
    expression = nil
  }

  var value: Double? {
    return expr?.valueWith(variableValues)
  }

}