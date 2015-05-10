//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

class CalculatorBrain {

  private enum Op: Printable {
    case Operand(Double)
    case Constant(String, Double)
    case Variable(String)
    case UnaryOperation(String, Double->Double)
    case BinaryOperation(String, (Double,Double)->Double)

    var description: String {
      switch self {
      case let .Operand(operand):
        return "\(operand)"
      case let .Constant(symbol, value):
        return symbol
      case let .Variable(symbol):
        return symbol
      case let .UnaryOperation(symbol, _):
        return symbol
      case let .BinaryOperation(symbol, _):
        return symbol
      }
    }
  }

  private var opStack = [Op]()
  private let knownOps: [String:Op]

  var variableValues = [String:Double]()
  
  init() {
    var initOps = [String:Op]()
    func initOp(op: Op) { initOps[op.description] = op }
    initOp(Op.BinaryOperation("×") { x, y in x * y })
    initOp(Op.BinaryOperation("÷") { x, y in y / x })
    initOp(Op.BinaryOperation("+") { x, y in x + y })
    initOp(Op.BinaryOperation("−") { x, y in y - x })
    initOp(Op.UnaryOperation("√", sqrt))
    initOp(Op.UnaryOperation("sin", sin))
    initOp(Op.UnaryOperation("cos", cos))
    initOp(Op.Constant("π", M_PI))
    knownOps = initOps
  }

  typealias PropertyList = AnyObject

  var program: PropertyList {
    get {
      let result: [String:AnyObject] = ["opStack":opStack.map { x in x.description }, "variableValues":variableValues]
      return result
    }
    set {
      let newProgram = newValue as? [String:AnyObject]
      if let newVariableValues = getVariableValuesFrom(newProgram), newOpStack = getOpStackFrom(newProgram) {
        variableValues = newVariableValues
        opStack = newOpStack
      } else {
        println("Error: failed to parse program")
      }
    }
  }

  private func getVariableValuesFrom(program: [String:AnyObject]?) -> [String:Double]? {
    return program?["variableValues"] as? [String:Double]
  }

  private func getOpStackFrom(program: [String:AnyObject]?) -> [Op]? {
    let newOps = program?["opStack"] as? [String]
    return newOps?.map { x in self.knownOps[x] ?? self.operandFromString(x) ?? Op.Variable(x) }
  }

  private func operandFromString(s: String) -> Op? {
    return flatMap(doubleFromString(s)) { x in Op.Operand(x) }
  }

  private func evaluate(var remainingOps: [Op]) -> (result: Double, remainingOps: [Op])? {
    if remainingOps.isEmpty { return nil }
    switch remainingOps.removeLast() {
    case let .Operand(operand):
      return (operand, remainingOps)
    case let .Constant(_, value):
      return (value, remainingOps)
    case let .Variable(symbol):
      return flatMap(variableValues[symbol]) { x in (x, remainingOps) }
    case let .UnaryOperation(_, operation):
      return unaryOp(operation, remainingOps)
    case let .BinaryOperation(_, operation):
      return binaryOp(operation, remainingOps)
    }
  }

  private func unaryOp(op: Double->Double, _ remainingOps: [Op]) -> (result: Double, remainingOps: [Op])? {
    let opEvaluation = evaluate(remainingOps)
    return flatMap(opEvaluation) { x in (op(x.result), x.remainingOps) }
  }

  private func binaryOp(op: (Double,Double)->Double, _ remainingOps: [Op]) -> (result: Double, remainingOps: [Op])? {
    let op1Evaluation = evaluate(remainingOps)
    let op2Evaluation = flatMap(op1Evaluation) { x in evaluate(x.remainingOps) }
    return flatMap(op1Evaluation, op2Evaluation) { x, y in (op(x.result, y.result), y.remainingOps) }
  }

  func evaluate() -> Double? {
    return flatMap(evaluate(opStack)) { x in x.result.isInfinite || x.result.isNaN ? nil : x.result }
  }

  func pushOperand(operand: Double) {
    opStack.append(.Operand(operand))
  }

  func performOperation(symbol: String) {
    opStack.append(knownOps[symbol] ?? Op.Variable(symbol))
  }

  func pushOperand(symbol: String) {
    opStack.append(.Variable(symbol))
  }

  func clear() {
    opStack = [Op]()
  }

  func clearVariables() {
    variableValues = [String:Double]()
  }

}


extension CalculatorBrain: Printable {

  var description: String {
    var remainingOps = opStack
    let expressions = GeneratorOf<String> {
      if remainingOps.isEmpty { return nil }
      let (expression, remaining) = self.getPreviousExpressionFrom(remainingOps)
      remainingOps = remaining
      return removeOutsideParenFrom(expression)
    }
    return ", ".join(Array(expressions).reverse())
  }

  private func getPreviousExpressionFrom(var remainingOps: [Op]) -> (symbol: String, remainingOps: [Op]) {
    if remainingOps.isEmpty { return (opStack.isEmpty ? "" : "?", remainingOps) }
    switch remainingOps.removeLast() {
    case let .Operand(operand):
      return (removeDecimalZeroFrom("\(operand)"), remainingOps)
    case let .Constant(symbol, _):
      return (symbol, remainingOps)
    case let .Variable(symbol):
      return (symbol, remainingOps)
    case let .UnaryOperation(symbol, _):
      return unaryOpDescription(symbol, remainingOps)
    case let .BinaryOperation(symbol, _):
      return binaryOpDescription(symbol, remainingOps)
    }
  }

  private func unaryOpDescription(symbol: String, _ remainingOps: [Op]) -> (symbol: String, remainingOps: [Op]) {
    let operand = getPreviousExpressionFrom(remainingOps)
    return (symbol + "(" + removeOutsideParenFrom(operand.symbol) + ")", operand.remainingOps)
  }

  private func binaryOpDescription(symbol: String, _ remainingOps: [Op]) -> (symbol: String, remainingOps: [Op]) {
    let operand1 = getPreviousExpressionFrom(remainingOps)
    let operand2 = getPreviousExpressionFrom(operand1.remainingOps)
    return ("(" + operand2.symbol + symbol + operand1.symbol + ")", operand2.remainingOps)
  }

}


private func removeOutsideParenFrom(s: String) -> String {
  if count(s) < 2 { return s }
  var result = Array(s)
  if result.first! == "(" && result.last! == ")" {
    result.removeAtIndex(result.startIndex)
    result.removeAtIndex(result.endIndex-1)
  }
  return String(result)
}
