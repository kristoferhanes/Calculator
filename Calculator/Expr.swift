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
      switch first {
      case "(":
        guard
          let (e1, rest1) = parse(rest),
          let (op, rest2) = decompose(rest1),
          let (e2, rest3) = parse(rest2)
          else { return nil }

        let restFinal = decompose(rest3)?.tail ?? ""
        switch op {
        case "+": return (.Add(e1, e2), restFinal)
        case "−": return (.Sub(e1, e2), restFinal)
        case "×": return (.Mul(e1, e2), restFinal)
        case "÷": return (.Div(e1, e2), restFinal)
        default: return nil
        }

      case "0"..."9", "-":
        let (succeeds, remainder) = takeWhile(rest, predicate: isNumeral)
        return (.Num(Double("\(first)" + succeeds)!), remainder)

      case "s":
        guard
          let (second, rest1) = decompose(rest) where second == "i",
          let (third, rest2) = decompose(rest1) where third == "n",
          let rest3 = decompose(rest2)?.tail
          else { fallthrough }
        guard let (e, rest4) = parse(rest3) else { return nil }
        let restFinal = decompose(rest4)?.tail ?? ""
        return (.Sin(e), restFinal)

      case "c":
        guard
          let (second, rest1) = decompose(rest) where second == "o",
          let (third, rest2) = decompose(rest1) where third == "s",
          let rest3 = decompose(rest2)?.tail
          else { fallthrough }
        guard let (e, rest4) = parse(rest3) else { return nil }
        let restFinal = decompose(rest4)?.tail ?? ""
        return (.Cos(e), restFinal)

      case "a"..."z", "A"..."Z":
        let (succeeds, remainder) = takeWhile(rest, predicate: isAlpha)
        return (.Var(String("\(first)" + succeeds)), remainder)

      default: return nil

      }
    }

    func isNumeral(c: Character) -> Bool {
      return "0"..."9" ~= c
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

    func decompose(str: String) -> (head: Character, tail: String)? {
      guard let first = str.characters.first else { return nil }
      let rest = String(str.characters.dropFirst())
      return (first, rest)
    }

    guard let expr = parse(input)?.expr else { return nil }
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











