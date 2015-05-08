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
    return flatMap(evaluate(opStack)) { x in
      println("\(opStack) = \(x.result) with \(x.remainingOps) left over.")
      return x.result
    }
  }

  func pushOperand(operand: Double) {
    opStack.append(.Operand(operand))
  }

  func performOperation(symbol: String) {
    let operation = knownOps[symbol] ?? Op.Variable(symbol)
    opStack.append(operation)
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
    let results = GeneratorOf<String> {
      if remainingOps.isEmpty { return nil }
      let (result, remaining) = self.getDescription(remainingOps)
      remainingOps = remaining
      return self.removeParen(result)
    }
    return ", ".join(reduce(results, [], { accum, x in [x] + accum }))
  }

  private func getDescription(var remainingOps: [Op]) -> (symbol: String, remainingOps: [Op]) {
    if remainingOps.isEmpty { return (opStack.isEmpty ? "" : "?", remainingOps) }
    switch remainingOps.removeLast() {
    case let .Operand(operand):
      return (stripDecimalZero("\(operand)"), remainingOps)
    case let .Constant(symbol, _):
      return ("\(symbol)", remainingOps)
    case let .Variable(symbol):
      return (symbol, remainingOps)
    case let .UnaryOperation(symbol, _):
      return unaryOpDescription(symbol, remainingOps)
    case let .BinaryOperation(symbol, _):
      return binaryOpDescription(symbol, remainingOps)
    }
  }

  private func unaryOpDescription(symbol: String, _ remainingOps: [Op]) -> (symbol: String, remainingOps: [Op]) {
    let operand = getDescription(remainingOps)
    return (symbol + "(" + removeParen("\(operand.symbol)") + ")", operand.remainingOps)
  }

  private func binaryOpDescription(symbol: String, _ remainingOps: [Op]) -> (symbol: String, remainingOps: [Op]) {
    let operand1 = getDescription(remainingOps)
    let operand2 = getDescription(operand1.remainingOps)
    return ("(" + operand2.symbol + symbol + operand1.symbol + ")", operand2.remainingOps)
  }

  private func stripDecimalZero(s: String) -> String {
    if count(s) < 2 { return s }
    var result = Array(s)
    let lastTwo = result.endIndex-2...result.endIndex-1
    let end = result[lastTwo]
    if end.first! == "." && end.last! == "0" {
      result.removeRange(lastTwo)
    }
    return String(result)
  }

  private func removeParen(s: String) -> String {
    if count(s) < 2 { return s }
    var result = Array(s)
    if result.first! == "(" && result.last! == ")" {
      result.removeAtIndex(result.startIndex)
      result.removeAtIndex(result.endIndex-1)
    }
    return String(result)
  }

}