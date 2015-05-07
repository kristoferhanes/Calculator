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
    case UnaryOperation(String, Double->Double)
    case BinaryOperation(String, (Double,Double)->Double)
    var description: String {
      switch self {
      case let .Operand(operand):
        return "\(operand)"
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
    func learnOp(op: Op) {
      initOps[op.description] = op
    }
    learnOp(Op.BinaryOperation("×") { x, y in x * y })
    learnOp(Op.BinaryOperation("÷") { x, y in y / x })
    learnOp(Op.BinaryOperation("+") { x, y in x + y })
    learnOp(Op.BinaryOperation("−") { x, y in y - x })
    learnOp(Op.UnaryOperation("√", sqrt))
    
    knownOps = initOps
  }

  private func evaluate(var remainingOps: [Op]) -> (result: Double, remainingOps: [Op])? {
    if remainingOps.isEmpty { return nil }
    switch remainingOps.removeLast() {
    case let .Operand(operand):
      return (operand, remainingOps)
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
    if let (result, remainder) = evaluate(opStack) {
      println("\(opStack) = \(result) with \(remainder) left over.")
      return result
    }
    return nil
  }

  func pushOperand(operand: Double) -> Double? {
    opStack.append(.Operand(operand))
    return evaluate()
  }

  func performOperation(symbol: String) -> Double? {
    if let operation = knownOps[symbol] {
      opStack.append(operation)
    }
    return evaluate()
  }

}

private func flatMap<T,U>(x: T?, y: T?, f: (T,T)->U?) -> U? {
  return flatMap(x) { x in flatMap(y) { y in f(x, y) } }
}