//
//  Expression.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2016 02 25.
//  Copyright © 2016 Kristofer Hanes. All rights reserved.
//

import Foundation

indirect enum Expression {
  case Num(Double)
  case Var(String)
  case Add(Expression, Expression)
  case Sub(Expression, Expression)
  case Mul(Expression, Expression)
  case Div(Expression, Expression)
  case Sqrt(Expression)
  case Sin(Expression)
  case Cos(Expression)
}

extension Expression {

  init?(parse input: String) {

    func parse(input: String) -> (Expression, String)? {
      guard let (first, rest) = decompose(input) else { return nil }
      if first == "(" {
        guard
          let (e1, rest1) = parse(rest),
          let (closeParen, rest2) = decompose(rest1) where closeParen == ")"
          else { return nil }
        let (e2, restFinal) = parseBinaryOperator(left: e1, remaining: rest2, precidence: false) ?? (e1, rest2)
        return (e2, restFinal)
      } else {
        guard let (e1, rest1) = parseDouble(input)
          ?? parseUnitaryOperator("√", from: input, with: Expression.Sqrt)
          ?? parseUnitaryOperator("sin", from: input, with: Expression.Sin)
          ?? parseUnitaryOperator("cos", from: input, with: Expression.Cos)
          ?? parseVariable(input)
          else { return nil }
        let (e2, restFinal) = parseBinaryOperator(left: e1, remaining: rest1, precidence: true) ?? (e1, rest1)
        return (e2, restFinal)
      }
    }

    func parseBinaryOperator(left left: Expression, remaining: String, precidence: Bool) -> (Expression, String)? {
      guard
        let (op, rest) = decompose(remaining),
        let (right, restFinal) = parse(rest)
        else { return nil }

      switch op {
      case "+": return (rotateOperation(.Add(left, right)), restFinal)
      case "−": return (rotateOperation(.Sub(left, right)), restFinal)
      case "×":
        let operation = precidence
          ? correctPrecidence(left: left, right: right, operation: Expression.Mul)
          : .Mul(left, right)
        return (rotateOperation(operation), restFinal)
      case "÷":
        let operation = precidence
          ? correctPrecidence(left: left, right: right, operation: Expression.Div)
          : .Div(left, right)
        return (rotateOperation(operation), restFinal)
      default: return nil
      }
    }

    func rotateOperation(expr: Expression) -> Expression {
      switch expr {

      case let .Add(e1, .Add(e2, e3)): return .Add(.Add(e1, e2), e3)
      case let .Add(e1, .Sub(e2, e3)): return .Sub(.Add(e1, e2), e3)
      case let .Sub(e1, .Add(e2, e3)): return .Add(.Sub(e1, e2), e3)
      case let .Sub(e1, .Sub(e2, e3)): return .Sub(.Sub(e1, e2), e3)

      case let .Mul(e1, .Mul(e2, e3)): return .Mul(.Mul(e1, e2), e3)
      case let .Mul(e1, .Div(e2, e3)): return .Div(.Mul(e1, e2), e3)
      case let .Div(e1, .Mul(e2, e3)): return .Mul(.Div(e1, e2), e3)
      case let .Div(e1, .Div(e2, e3)): return .Div(.Div(e1, e2), e3)

      default: return expr
      }
    }

    func correctPrecidence(left left: Expression, right: Expression, operation: (Expression,Expression)->Expression) -> Expression {
      switch right {
      case let .Add(e1, e2): return .Add(operation(left, e1), e2)
      case let .Sub(e1, e2): return .Sub(operation(left, e1), e2)
      default: return operation(left, right)
      }
    }

    func parseDouble(input: String) -> (Expression, String)? {
      guard let (first, rest) = decompose(input) else { return nil }
      switch first {
      case "0"..."9", "-", ".":
        let (succeeds, remainder) = splitWhile(rest, predicate: isNumeral)
        return (.Num(Double("\(first)" + succeeds)!), remainder)
      default: return nil
      }
    }

    func parseVariable(input: String) -> (Expression, String)? {
      guard let first = decompose(input)?.head where isAlpha(first)
        else { return nil }
      let (succeeds, remainder) = splitWhile(input, predicate: isAlpha)
      return (.Var(succeeds), remainder)
    }

    func parseUnitaryOperator(opStr: String, from input: String,
      with expr: Expression->Expression) -> (Expression, String)? {
        guard
          input.hasPrefix(opStr),
          let rest = dropPrefix(opStr, from: input),
          let (e, restFinal) = parse(rest)
          else { return nil }
        return (expr(e), restFinal)
    }

    func isNumeral(c: Character) -> Bool {
      return "0"..."9" ~= c || "." == c
    }

    func isAlpha(c: Character) -> Bool {
      return "a"..."z" ~= c || "A"..."Z" ~= c || "π" == c
    }

    func splitWhile(str: String, predicate: Character->Bool) -> (String, String) {
      var taken = ""
      var remaining = str

      while let (c, r) = decompose(remaining) where predicate(c) {
        taken.append(c)
        remaining = r
      }

      return (taken, remaining)
    }

    func dropPrefix(drop: String, from str: String) -> String? {
      let dropCount = str.characters.count - drop.characters.count
      guard drop == String(str.characters.dropLast(dropCount)) else { return nil }
      return String(str.characters.dropFirst(drop.characters.count))
    }

    func decompose(str: String) -> (head: Character, tail: String)? {
      guard let first = str.characters.first else { return nil }
      let rest = String(str.characters.dropFirst())
      return (first, rest)
    }

    guard let (expr, remaining) = parse(input) where remaining == ""
      else { return nil }
    self = expr
  }

  func valueWith(env: [String:Double]) -> Double? {

    func combine(e1: Expression, _ e2: Expression, with op: (Double, Double)->Double) -> Double? {
      guard
        let n1 = e1.valueWith(env),
        let n2 = e2.valueWith(env)
        else { return nil }
      return op(n1, n2)
    }

    switch self {
    case let .Num(n): return n
    case let .Var(s): return env[s]
    case let .Add(e1, e2): return combine(e1, e2, with: +)
    case let .Sub(e1, e2): return combine(e1, e2, with: -)
    case let .Mul(e1, e2): return combine(e1, e2, with: *)
    case let .Div(e1, e2): return combine(e1, e2, with: /)
    case let .Sqrt(e): return e.valueWith(env).map(sqrt)
    case let .Sin(e): return e.valueWith(env).map(sin)
    case let .Cos(e): return e.valueWith(env).map(cos)
    }
  }

  var value: Double? {
    return valueWith([:])
  }

}

extension Expression: Equatable {  }

func == (lhs: Expression, rhs: Expression) -> Bool {
  switch (lhs, rhs) {
  case let (.Num(l), .Num(r)): return l == r
  case let (.Var(l), .Var(r)): return l == r
  case let (.Add(e1, e2), .Add(e3, e4)): return e1 == e3 && e2 == e4
  case let (.Sub(e1, e2), .Sub(e3, e4)): return e1 == e3 && e2 == e4
  case let (.Mul(e1, e2), .Mul(e3, e4)): return e1 == e3 && e2 == e4
  case let (.Div(e1, e2), .Div(e3, e4)): return e1 == e3 && e2 == e4
  case let (.Sqrt(e1), .Sqrt(e2)): return e1 == e2
  case let (.Sin(e1), .Sin(e2)): return e1 == e2
  case let (.Cos(e1), .Cos(e2)): return e1 == e2
  default: return false
  }
}

extension Expression: CustomStringConvertible {

  var description: String {

    func toString(expr: Expression) -> String {
      switch expr {
      case let .Num(n): return "\(n)"
      case let .Var(s): return s
      case let .Add(e1, e2): return "(\(toString(e1))+\(toString(e2)))"
      case let .Sub(e1, e2): return "(\(toString(e1))−\(toString(e2)))"
      case let .Mul(e1, e2): return "(\(toString(e1))×\(toString(e2)))"
      case let .Div(e1, e2): return "(\(toString(e1))÷\(toString(e2)))"
      case let .Sqrt(e): return "sqrt(\(toString(e)))"
      case let .Sin(e): return "sin(\(toString(e)))"
      case let .Cos(e): return "cos(\(toString(e)))"
      }
    }

    func removeOutsideParens(str: String) -> String {
      guard str.characters.first == "(" && str.characters.last == ")"
        else { return str }
      return String(str.characters.dropFirst().dropLast())
    }

    return removeOutsideParens(toString(self))
  }

}
