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
    case UnaryOperation(String, Double->Double)
    case BinaryOperation(String, (Double,Double)->Double)
    var description: String {
      switch self {
      case let .Operand(operand):
        return "\(operand)"
      case let .Constant(symbol, value):
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
      return opStack.map { x in x.description }
    }
    set {
      let opSymbols = newValue as? [String]
      let newOpStack = opSymbols?.map { x in self.knownOps[x] ?? flatMap(doubleFromString(x)) { x in Op.Operand(x) } }
      opStack = (newOpStack?.filter { x in x != nil })?.map { x in x! } ?? opStack
    }
  }

  private func evaluate(var remainingOps: [Op]) -> (result: Double, remainingOps: [Op])? {
    if remainingOps.isEmpty { return nil }
    switch remainingOps.removeLast() {
    case let .Operand(operand):
      return (operand, remainingOps)
    case let .Constant(_, value):
      return (value, remainingOps)
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
    return flatMap(evaluate(opStack)) { x in
      println("\(opStack) = \(x.result) with \(x.remainingOps) left over.")
      return x.result
    }
  }

  func pushOperand(operand: Double) {
    opStack.append(.Operand(operand))
  }

  func performOperation(symbol: String) {
    if let operation = knownOps[symbol] {
      opStack.append(operation)
    }
  }

  func clear() {
    opStack = [Op]()
  }

  var history: String {
    return opStack.isEmpty ? "" : "\(opStack)"
  }

}