//
//  Expression.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2016 02 25.
//  Copyright © 2016 Kristofer Hanes. All rights reserved.
//

import Foundation

indirect enum Expression {
  case num(Double)
  case `var`(String)
  case paren(Expression)
  case add(Expression, Expression)
  case sub(Expression, Expression)
  case mul(Expression, Expression)
  case div(Expression, Expression)
  case sqrt(Expression)
  case sin(Expression)
  case cos(Expression)
}

extension Expression {

  init?(parse input: String) {

    typealias Stream = String.CharacterView

    func parse(_ input: Stream) -> (Expression, Stream)? {
      guard let (first, rest) = decompose(input) else { return nil }
      if first == "(" {
        guard
          let (e1, rest1) = parse(rest),
          let (closeParen, rest2) = decompose(rest1),
          closeParen == ")"
          else { return nil }
        let (e2, rest3) = (Expression.paren(e1), rest2)
        let (e3, restFinal) = parseBinaryOperator(left: e2, remaining: rest3) ?? (e2, rest3)
        return (e3, restFinal)
      } else {
        guard let (e1, rest1) = parseDouble(input)
          ?? parseUnitaryOperator("√", from: input, with: Expression.sqrt)
          ?? parseUnitaryOperator("sin", from: input, with: Expression.sin)
          ?? parseUnitaryOperator("cos", from: input, with: Expression.cos)
          ?? parseVariable(input)
          else { return nil }

        let (e2, restFinal) = parseBinaryOperator(left: e1, remaining: rest1) ?? (e1, rest1)
        return (e2, restFinal)
      }
    }

    func parseBinaryOperator(left: Expression, remaining: Stream) -> (Expression, Stream)? {

      guard
        let (op, rest) = decompose(remaining),
        let (right, restFinal) = parse(rest)
        else { return nil }

      switch op {
      case "+": return (rotateOperation(.add(left, right)), restFinal)
      case "−": return (rotateOperation(.sub(left, right)), restFinal)
      case "×":
        let operation = correctPrecidence(left: left, right: right, operation: Expression.mul)
        return (rotateOperation(operation), restFinal)
      case "÷":
        let operation = correctPrecidence(left: left, right: right, operation: Expression.div)
        return (rotateOperation(operation), restFinal)
      default: return nil
      }
    }

    func rotateOperation(_ expr: Expression) -> Expression {
      switch expr {

      case let .add(e1, .add(e2, e3)): return .add(.add(e1, e2), e3)
      case let .add(e1, .sub(e2, e3)): return .sub(.add(e1, e2), e3)
      case let .sub(e1, .add(e2, e3)): return .add(.sub(e1, e2), e3)
      case let .sub(e1, .sub(e2, e3)): return .sub(.sub(e1, e2), e3)

      case let .mul(e1, .mul(e2, e3)): return .mul(.mul(e1, e2), e3)
      case let .mul(e1, .div(e2, e3)): return .div(.mul(e1, e2), e3)
      case let .div(e1, .mul(e2, e3)): return .mul(.div(e1, e2), e3)
      case let .div(e1, .div(e2, e3)): return .div(.div(e1, e2), e3)

      default: return expr
      }
    }

    func correctPrecidence(left: Expression, right: Expression,
                                operation: (Expression,Expression)->Expression) -> Expression {
      switch right {
      case let .add(e1, e2): return .add(operation(left, e1), e2)
      case let .sub(e1, e2): return .sub(operation(left, e1), e2)
      default: return operation(left, right)
      }
    }

    func parseDouble(_ input: Stream) -> (Expression, Stream)? {
      guard let (first, rest) = decompose(input) else { return nil }

      func parseDouble(withPrefix prefix: String) -> (Expression, Stream) {
        let (succeeds, remainder) = splitWhile(rest, predicate: isNumeral)
        return (.num(Double(prefix + "\(first)" + String(succeeds))!), remainder)
      }

      switch first {
      case "0"..."9", "-":
        return parseDouble(withPrefix: "")
      case ".":
        return parseDouble(withPrefix: "0")
      default: return nil
      }
    }

    func parseVariable(_ input: Stream) -> (Expression, Stream)? {
      guard let first = decompose(input)?.head , isAlpha(first)
        else { return nil }
      let (succeeds, remainder) = splitWhile(input, predicate: isAlpha)
      return (.var(String(succeeds)), remainder)
    }

    func parseUnitaryOperator(_ opStr: String, from input: Stream,
                              with expr: (Expression)->Expression) -> (Expression, Stream)? {
      guard
        let rest = dropPrefix(opStr.characters, from: input),
        let (e, restFinal) = parse(rest)
        else { return nil }
      return (expr(e), restFinal)
    }

    func isNumeral(_ c: Character) -> Bool {
      return "0"..."9" ~= c || "." == c
    }

    func isAlpha(_ c: Character) -> Bool {
      return "a"..."z" ~= c || "A"..."Z" ~= c || "π" == c
    }

    func splitWhile(_ str: Stream, predicate: (Character)->Bool) -> (Stream, Stream) {
      var taken = String.CharacterView()
      var remaining = str

      while let (c, r) = decompose(remaining), predicate(c) {
        taken.append(c)
        remaining = r
      }

      return (taken, remaining)
    }

    func dropPrefix(_ drop: Stream, from str: Stream) -> Stream? {
      guard String(str).hasPrefix(String(drop)) else { return nil }
      return str.dropFirst(drop.count)
    }

    func decompose(_ str: Stream) -> (head: Character, tail: Stream)? {
      return str.first.map { ($0, str.dropFirst()) }
    }

    guard let (expr, remaining) = parse(input.characters), remaining.isEmpty
      else { return nil }
    self = expr
  }

  func value(with env: [String:Double]) -> Double? {

    func combine(_ e1: Expression, _ e2: Expression, with op: (Double, Double)->Double) -> Double? {
      guard
        let n1 = e1.value(with: env),
        let n2 = e2.value(with: env)
        else { return nil }
      return op(n1, n2)
    }

    switch self {
    case let .num(n): return n
    case let .var(s): return env[s]
    case let .paren(e): return e.value(with: env)
    case let .add(e1, e2): return combine(e1, e2, with: +)
    case let .sub(e1, e2): return combine(e1, e2, with: -)
    case let .mul(e1, e2): return combine(e1, e2, with: *)
    case let .div(e1, e2): return combine(e1, e2, with: /)
    case let .sqrt(e): return e.value(with: env).map(Foundation.sqrt)
    case let .sin(e): return e.value(with: env).map(Foundation.sin)
    case let .cos(e): return e.value(with: env).map(Foundation.cos)
    }
  }

  var value: Double? {
    return value(with: [:])
  }

}

extension Expression: Equatable {
  static func == (lhs: Expression, rhs: Expression) -> Bool {
    switch (lhs, rhs) {
    case let (.num(l), .num(r)): return l == r
    case let (.var(l), .var(r)): return l == r
    case let (.paren(l), .paren(r)): return l == r
    case let (.add(e1, e2), .add(e3, e4)): return e1 == e3 && e2 == e4
    case let (.sub(e1, e2), .sub(e3, e4)): return e1 == e3 && e2 == e4
    case let (.mul(e1, e2), .mul(e3, e4)): return e1 == e3 && e2 == e4
    case let (.div(e1, e2), .div(e3, e4)): return e1 == e3 && e2 == e4
    case let (.sqrt(e1), .sqrt(e2)): return e1 == e2
    case let (.sin(e1), .sin(e2)): return e1 == e2
    case let (.cos(e1), .cos(e2)): return e1 == e2
    default: return false
    }
  }
}

extension Expression: CustomStringConvertible {

  var description: String {
    switch self {
    case let .num(n): return "\(n)"
    case let .var(s): return s
    case let .paren(e): return "(\(e))"
    case let .add(e1, e2): return "\(e1)+\(e2)"
    case let .sub(e1, e2): return "\(e1)−\(e2)"
    case let .mul(e1, e2): return "\(e1)×\(e2)"
    case let .div(e1, e2): return "\(e1)÷\(e2)"
    case let .sqrt(e): return "sqrt(\(e))"
    case let .sin(e): return "sin(\(e))"
    case let .cos(e): return "cos(\(e))"
    }
  }
  
}
