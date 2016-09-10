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
  case Paren(Expression)
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

    typealias Stream = String.CharacterView

    func parse(input: Stream) -> (Expression, Stream)? {
      guard let (first, rest) = decompose(input) else { return nil }
      if first == "(" {
        guard
          let (e1, rest1) = parse(rest),
          let (closeParen, rest2) = decompose(rest1) where closeParen == ")"
          else { return nil }
        let (e2, rest3) = (Expression.Paren(e1), rest2)
        let (e3, restFinal) = parseBinaryOperator(left: e2, remaining: rest3) ?? (e2, rest3)
        return (e3, restFinal)
      } else {
        guard let (e1, rest1) = parseDouble(input)
          ?? parseUnitaryOperator("√", from: input, with: Expression.Sqrt)
          ?? parseUnitaryOperator("sin", from: input, with: Expression.Sin)
          ?? parseUnitaryOperator("cos", from: input, with: Expression.Cos)
          ?? parseVariable(input)
          else { return nil }

        let (e2, restFinal) = parseBinaryOperator(left: e1, remaining: rest1) ?? (e1, rest1)
        return (e2, restFinal)
      }
    }

    func parseBinaryOperator(left left: Expression, remaining: Stream) -> (Expression, Stream)? {

      guard
        let (op, rest) = decompose(remaining),
        let (right, restFinal) = parse(rest)
        else { return nil }

      switch op {
      case "+": return (rotateOperation(.Add(left, right)), restFinal)
      case "−": return (rotateOperation(.Sub(left, right)), restFinal)
      case "×":
        let operation = correctPrecidence(left: left, right: right, operation: Expression.Mul)
        return (rotateOperation(operation), restFinal)
      case "÷":
        let operation = correctPrecidence(left: left, right: right, operation: Expression.Div)
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

    func correctPrecidence(left left: Expression, right: Expression,
                                operation: (Expression,Expression)->Expression) -> Expression {
      switch right {
      case let .Add(e1, e2): return .Add(operation(left, e1), e2)
      case let .Sub(e1, e2): return .Sub(operation(left, e1), e2)
      default: return operation(left, right)
      }
    }

    func parseDouble(input: Stream) -> (Expression, Stream)? {
      guard let (first, rest) = decompose(input) else { return nil }

      func parseDouble(withPrefix prefix: String) -> (Expression, Stream) {
        let (succeeds, remainder) = splitWhile(rest, predicate: isNumeral)
        return (.Num(Double(prefix + "\(first)" + String(succeeds))!), remainder)
      }

      switch first {
      case "0"..."9", "-":
        return parseDouble(withPrefix: "")
      case ".":
        return parseDouble(withPrefix: "0")
      default: return nil
      }
    }

    func parseVariable(input: Stream) -> (Expression, Stream)? {
      guard let first = decompose(input)?.head where isAlpha(first)
        else { return nil }
      let (succeeds, remainder) = splitWhile(input, predicate: isAlpha)
      return (.Var(String(succeeds)), remainder)
    }

    func parseUnitaryOperator(opStr: String, from input: Stream,
                              with expr: Expression->Expression) -> (Expression, Stream)? {
      guard
        let rest = dropPrefix(opStr.characters, from: input),
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

    func splitWhile(str: Stream, predicate: Character->Bool) -> (Stream, Stream) {
      var taken = String.CharacterView()
      var remaining = str

      while let (c, r) = decompose(remaining) where predicate(c) {
        taken.append(c)
        remaining = r
      }

      return (taken, remaining)
    }

    func dropPrefix(drop: Stream, from str: Stream) -> Stream? {
      guard String(str).hasPrefix(String(drop)) else { return nil }
      return str.dropFirst(drop.count)
    }

    func decompose(str: Stream) -> (head: Character, tail: Stream)? {
      guard let first = str.first else { return nil }
      let rest = str.dropFirst()
      return (first, rest)
    }

    guard let (expr, remaining) = parse(input.characters) where remaining.isEmpty
      else { return nil }
    self = expr
  }

  func value(with env: [String:Double]) -> Double? {

    func combine(e1: Expression, _ e2: Expression, with op: (Double, Double)->Double) -> Double? {
      guard
        let n1 = e1.value(with: env),
        let n2 = e2.value(with: env)
        else { return nil }
      return op(n1, n2)
    }

    switch self {
    case let .Num(n): return n
    case let .Var(s): return env[s]
    case let .Paren(e): return e.value(with: env)
    case let .Add(e1, e2): return combine(e1, e2, with: +)
    case let .Sub(e1, e2): return combine(e1, e2, with: -)
    case let .Mul(e1, e2): return combine(e1, e2, with: *)
    case let .Div(e1, e2): return combine(e1, e2, with: /)
    case let .Sqrt(e): return e.value(with: env).map(sqrt)
    case let .Sin(e): return e.value(with: env).map(sin)
    case let .Cos(e): return e.value(with: env).map(cos)
    }
  }

  var value: Double? {
    return value(with: [:])
  }

}

extension Expression: Equatable {  }

func == (lhs: Expression, rhs: Expression) -> Bool {
  switch (lhs, rhs) {
  case let (.Num(l), .Num(r)): return l == r
  case let (.Var(l), .Var(r)): return l == r
  case let (.Paren(l), .Paren(r)): return l == r
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
    switch self {
    case let .Num(n): return "\(n)"
    case let .Var(s): return s
    case let .Paren(e): return "(\(e))"
    case let .Add(e1, e2): return "\(e1)+\(e2)"
    case let .Sub(e1, e2): return "\(e1)−\(e2)"
    case let .Mul(e1, e2): return "\(e1)×\(e2)"
    case let .Div(e1, e2): return "\(e1)÷\(e2)"
    case let .Sqrt(e): return "sqrt(\(e))"
    case let .Sin(e): return "sin(\(e))"
    case let .Cos(e): return "cos(\(e))"
    }
  }
  
}
