//
//  Expr.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2016 02 25.
//  Copyright © 2016 Kristofer Hanes. All rights reserved.
//

import Foundation

indirect enum Expr {
  case Num(Double)
  case Var(String)
  case Add(Expr, Expr)
  case Sub(Expr, Expr)
  case Mul(Expr, Expr)
  case Div(Expr, Expr)
  case Sqrt(Expr)
  case Sin(Expr)
  case Cos(Expr)
}

extension Expr {
  init?(parse input: String) {

    func parse(input: String) -> (expr: Expr, rest: String)? {
      guard let (first, rest) = decompose(input) else { return nil }
      if first == "(" {
        guard
          let (e1, rest1) = parse(rest),
          let (closeParen, restFinal) = decompose(rest1) where closeParen == ")"
          else { return nil }
        return (e1, restFinal)
      } else {
        guard let (e1, rest1) = parseDouble(input)
          ?? parseUnitaryOperator("√", from: input, with: Expr.Sqrt)
          ?? parseUnitaryOperator("sin", from: input, with: Expr.Sin)
          ?? parseUnitaryOperator("cos", from: input, with: Expr.Cos)
          ?? parseVariable(input)
          else { return nil }
        let (e2, restFinal) = parseBinaryOperatorWithLeftExpr(e1, remaining: rest1) ?? (e1, rest1)
        return (e2, restFinal)
      }
    }

    func parseBinaryOperatorWithLeftExpr(left: Expr, remaining: String) -> (expr: Expr, rest: String)? {
      guard
        let (op, rest) = decompose(remaining),
        let (right, restFinal) = parse(rest)
        else { return nil }

      // TODO: Add support for operator precidence.

      switch op {
      case "+": return (.Add(left, right), restFinal)
      case "−": return (.Sub(left, right), restFinal)
      case "×": return (.Mul(left, right), restFinal)
      case "÷": return (.Div(left, right), restFinal)
      default: return nil
      }
    }

    func correctPrecidence(left left: Expr, right: Expr, operation: (Expr,Expr)->Expr) -> Expr {
      switch right {
      case let .Mul(e1, e2): return .Mul(operation(left, e1), e2)
      case let .Div(e1, e2): return .Div(operation(left, e1), e2)
      default: return operation(left, right)
      }
    }

    func parseDouble(input: String) -> (expr: Expr, rest: String)? {
      guard let (first, rest) = decompose(input) else { return nil }
      switch first {
      case "0"..."9", "-", ".":
        let (succeeds, remainder) = takeWhile(rest, predicate: isNumeral)
        return (.Num(Double("\(first)" + succeeds)!), remainder)
      default: return nil
      }
    }

    func parseVariable(input: String) -> (expr: Expr, rest: String)? {
      guard let first = decompose(input)?.head where isAlpha(first)
        else { return nil }
      let (succeeds, remainder) = takeWhile(input, predicate: isAlpha)
      return (.Var(succeeds), remainder)
    }

    func parseBinaryOperator(input: String) -> (expr: Expr, rest: String)? {
      guard
        let (e1, rest) = parse(input),
        let (op, rest1) = decompose(rest),
        let (e2, restFinal) = parse(rest1)
        else { return nil }

      switch op {
      case "+": return (.Add(e1, e2), restFinal)
      case "−": return (.Sub(e1, e2), restFinal)
      case "×": return (.Mul(e1, e2), restFinal)
      case "÷": return (.Div(e1, e2), restFinal)
      default: return nil
      }
    }

    func parseUnitaryOperator(opStr: String, from input: String,
      with expr: Expr->Expr) -> (expr: Expr, rest: String)? {
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
      return "a"..."z" ~= c || "A"..."Z" ~= c
    }

    func takeWhile(str: String, predicate: Character->Bool) -> (String, String) {
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
}

extension Expr: Equatable {  }

func == (lhs: Expr, rhs: Expr) -> Bool {
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











