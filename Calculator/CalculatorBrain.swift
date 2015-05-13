//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

class CalculatorBrain {

  struct Constants {
    static let OpStackProgramKey = "OpStackProgramKey"
    static let VariableValuesProgramKey = "VariableValuesProgramKey"
  }

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

  typealias VariableValuesType = [String:Double]
  var variableValues = VariableValuesType()

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
      let result: [String:AnyObject] = [
        Constants.OpStackProgramKey:opStack.map { x in x.description },
        Constants.VariableValuesProgramKey:variableValues
      ]
      return result
    }
    set {
      let newProgram = newValue as? [String:AnyObject]
      if let newVariableValues = getVariableValuesFrom(newProgram), newOpStack = getOpStackFrom(newProgram) {
        variableValues = newVariableValues
        opStack = newOpStack
      } else {
        println("failed to parse program")
      }
    }
  }

  private func getVariableValuesFrom(program: [String:AnyObject]?) -> VariableValuesType? {
    return program?[Constants.VariableValuesProgramKey] as? VariableValuesType
  }

  private func getOpStackFrom(program: [String:AnyObject]?) -> [Op]? {
    let newOps = program?[Constants.OpStackProgramKey] as? [String]
    return newOps?.map { x in self.knownOps[x] ?? self.operandFromString(x) ?? Op.Variable(x) }
  }

  private func operandFromString(s: String) -> Op? {
    return flatMap(doubleFromString(s)) { x in Op.Operand(x) }
  }

  private func evaluate(remainingOps: ArraySlice<Op>) -> (result: Double, remainingOps: ArraySlice<Op>)? {
    if remainingOps.isEmpty { return nil }
    let remaining = remainingOps[0..<remainingOps.endIndex-1]
    switch remainingOps.last! {
    case let .Operand(operand):
      return (operand, remaining)
    case let .Constant(_, value):
      return (value, remaining)
    case let .Variable(symbol):
      return flatMap(variableValues[symbol]) { x in (x, remaining) }
    case let .UnaryOperation(_, operation):
      return unaryOp(operation, remaining)
    case let .BinaryOperation(_, operation):
      return binaryOp(operation, remaining)
    }
  }

  private func unaryOp(op: Double->Double, _ remainingOps: ArraySlice<Op>) -> (Double, ArraySlice<Op>)? {
    let opEvaluation = evaluate(remainingOps)
    return flatMap(opEvaluation) { x in (op(x.result), x.remainingOps) }
  }

  private func binaryOp(op: (Double,Double)->Double, _ remainingOps: ArraySlice<Op>) -> (Double, ArraySlice<Op>)? {
    let op1Evaluation = evaluate(remainingOps)
    let op2Evaluation = flatMap(op1Evaluation) { x in evaluate(x.remainingOps) }
    return flatMap(op1Evaluation, op2Evaluation) { x, y in (op(x.result, y.result), y.remainingOps) }
  }

  func evaluate() -> Double? {
    return flatMap(evaluate(ArraySlice(opStack))) { x in x.result.isInfinite || x.result.isNaN ? nil : x.result }
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
    variableValues = VariableValuesType()
  }

}

extension CalculatorBrain: Printable {

  var description: String {
    return ", ".join(expressions(ArraySlice(opStack)))
  }

  private func expressions(remainingOps: ArraySlice<Op>) -> [String] {
    if remainingOps.isEmpty { return [] }
    let (expression, remaining) = nextExpression(remainingOps)
    return expressions(remaining) + [removeOutsideParen(expression)]
  }

  private func nextExpression(remainingOps: ArraySlice<Op>) -> (symbol: String, remainingOps: ArraySlice<Op>) {
    if remainingOps.isEmpty { return (opStack.isEmpty ? "" : "?", remainingOps) }
    let remaining = remainingOps[0..<remainingOps.endIndex-1]
    switch remainingOps.last! {
    case let .Operand(operand):
      return (removeDecimalZeroFrom("\(operand)"), remaining)
    case let .Constant(symbol, _):
      return (symbol, remaining)
    case let .Variable(symbol):
      return (symbol, remaining)
    case let .UnaryOperation(symbol, _):
      return unaryOpDescription(symbol, remaining)
    case let .BinaryOperation(symbol, _):
      return binaryOpDescription(symbol, remaining)
    }
  }

  private func unaryOpDescription(opSymbol: String, _ remainingOps: ArraySlice<Op>) -> (String, ArraySlice<Op>) {
    let operand = nextExpression(remainingOps)
    return (opSymbol + "(" + removeOutsideParen(operand.symbol) + ")", operand.remainingOps)
  }

  private func binaryOpDescription(opSymbol: String, _ remainingOps: ArraySlice<Op>) -> (String, ArraySlice<Op>) {
    let operand1 = nextExpression(remainingOps)
    let operand2 = nextExpression(operand1.remainingOps)
    return ("(" + operand2.symbol + opSymbol + operand1.symbol + ")", operand2.remainingOps)
  }

}

private func removeOutsideParen(s: String) -> String {
  if count(s) < 2 { return s }
  let start = advance(s.startIndex, 1)
  let end = advance(s.startIndex, count(s)-1)
  return first(s) == "(" && last(s) == ")" ? s[start..<end] : s
}
