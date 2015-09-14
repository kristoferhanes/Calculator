//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import Foundation

final class CalculatorBrain {

  struct Constants {
    static let OpStackProgramKey = "OpStackProgramKey"
    static let VariableValuesProgramKey = "VariableValuesProgramKey"
  }

  private enum Op: CustomStringConvertible {
    case Operand(Double)
    case Constant(String, Double)
    case Variable(String)
    case UnaryOperation(String, Double->Double)
    case BinaryOperation(String, (Double,Double)->Double)

    var description: String {
      switch self {
      case let .Operand(operand):
        return "\(operand)"
      case let .Constant(symbol, _):
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

  typealias VariablesType = [String:Double]
  var variableValues = VariablesType()

  init() {
    var initOps = [String:Op]()
    func initOp(op: Op) { initOps[op.description] = op }
    initOp(Op.BinaryOperation("×") { $0 * $1 })
    initOp(Op.BinaryOperation("÷") { $1 / $0 })
    initOp(Op.BinaryOperation("+") { $0 + $1 })
    initOp(Op.BinaryOperation("−") { $1 - $0 })
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
        Constants.OpStackProgramKey:opStack.map { $0.description },
        Constants.VariableValuesProgramKey:variableValues
      ]
      return result
    }
    set {
      let newProgram = newValue as? [String:AnyObject]
      if let newVariableValues = variableValuesFrom(newProgram),
        newOpStack = opStackFrom(newProgram) {
          variableValues = newVariableValues
          opStack = newOpStack
      } else {
        print("failed to parse program")
      }
    }
  }

  private func variableValuesFrom(program: [String:AnyObject]?) -> VariablesType? {
    return program?[Constants.VariableValuesProgramKey] as? VariablesType
  }

  private func opStackFrom(program: [String:AnyObject]?) -> [Op]? {
    let newOps = program?[Constants.OpStackProgramKey] as? [String]
    return newOps?.map {
      self.knownOps[$0] ?? self.operandFromString($0) ?? Op.Variable($0) }
  }

  private func operandFromString(s: String) -> Op? {
    return Double(string: s).map { Op.Operand($0) }
  }

  private func evaluate(remainingOps: ArraySlice<Op>) ->
    (result: Double, remainingOps: ArraySlice<Op>)? {

      guard !remainingOps.isEmpty else { return nil }
      let remaining = remainingOps.dropLast()
      switch remainingOps.last! {
      case let .Operand(operand):
        return (operand, remaining)
      case let .Constant(_, value):
        return (value, remaining)
      case let .Variable(symbol):
        return variableValues[symbol].map { ($0, remaining) }
      case let .UnaryOperation(_, operation):
        return unaryOp(operation, remaining)
      case let .BinaryOperation(_, operation):
        return binaryOp(operation, remaining)
      }
  }

  private func unaryOp(op: Double->Double,
    _ remainingOps: ArraySlice<Op>) -> (Double, ArraySlice<Op>)? {

      let opEvaluation = evaluate(remainingOps)
      return opEvaluation.map { opEval in (op(opEval.result), opEval.remainingOps) }
  }

  private func binaryOp(op: (Double,Double)->Double,
    _ remainingOps: ArraySlice<Op>) -> (Double, ArraySlice<Op>)? {

      let op1Evaluation = evaluate(remainingOps)
      let op2Evaluation = op1Evaluation.flatMap { evaluate($0.remainingOps) }
      return zip(op1Evaluation, op2Evaluation).map { op1Eval, op2Eval in
        (op(op1Eval.result, op2Eval.result), op2Eval.remainingOps) }
  }

  func evaluate() -> Double? {
    return evaluate(ArraySlice(opStack)).flatMap { op in
      op.result.isInfinite || op.result.isNaN ? nil : op.result }
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
    variableValues = VariablesType()
  }

}

extension CalculatorBrain: CustomStringConvertible {

  var description: String {
    return opStack.isEmpty ? "" : expressions(ArraySlice(opStack)).joinWithSeparator(", ")
  }

  private func expressions(remainingOps: ArraySlice<Op>) -> [String] {
    guard !remainingOps.isEmpty else { return [] }
    let (expression, remaining) = nextExpression(remainingOps)
    return expressions(remaining) + [expression.removeOutsideParen()]
  }

  private func nextExpression(remainingOps: ArraySlice<Op>) ->
    (expression: String, remaining: ArraySlice<Op>) {

      guard !remainingOps.isEmpty else { return ("?", remainingOps) }
      let remaining = remainingOps.dropLast()
      switch remainingOps.last! {
      case let .Operand(operand):
        return ("\(operand)".removeDecimalZero(), remaining)
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

  private func unaryOpDescription(opSymbol: String,
    _ remainingOps: ArraySlice<Op>) -> (String, ArraySlice<Op>) {

      let (expression, remaining) = nextExpression(remainingOps)
      return (opSymbol + "(" + expression.removeOutsideParen() + ")", remaining)
  }

  private func binaryOpDescription(opSymbol: String,
    _ remainingOps: ArraySlice<Op>) -> (String, ArraySlice<Op>) {

      let op1 = nextExpression(remainingOps)
      let op2 = nextExpression(op1.remaining)
      return ("(" + op2.expression + opSymbol + op1.expression + ")", op2.remaining)
  }

}

extension String {

  private func removeOutsideParen() -> String {
    guard self.characters.count > 1 else { return self }
    let start = startIndex.advancedBy(1)
    let end = startIndex.advancedBy(self.characters.count-1)
    return self.characters.first == "(" && self.characters.last == ")"
      ? self[start..<end]
      : self
  }
  
}
