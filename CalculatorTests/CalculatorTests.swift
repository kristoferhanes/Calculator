//
//  CalculatorTests.swift
//  CalculatorTests
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit
import XCTest
@testable import Calculator

class CalculatorTests: XCTestCase {

  func testExpressionParse() {
    XCTAssertEqual(
      Expression(parse: "12"),
      .Num(12.0)
    )
    XCTAssertEqual(
      Expression(parse: "(12)"),
      .Paren(.Num(12.0))
    )
    XCTAssertEqual(
      Expression(parse: "(1+2)"),
      .Paren(.Add(.Num(1.0), .Num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(1−2)"),
      .Paren(.Sub(.Num(1.0), .Num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(1×2)"),
      .Paren(.Mul(.Num(1.0), .Num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(1÷2)"),
      .Paren(.Div(.Num(1.0), .Num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "sin(23+2)"),
      .Sin(.Paren(.Add(.Num(23.0), .Num(2.0))))
    )
    XCTAssertEqual(
      Expression(parse: "cos(34)"),
      .Cos(.Paren(.Num(34.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(√(5+45))"),
      .Paren(.Sqrt(.Paren(.Add(.Num(5.0), .Num(45.0)))))
    )
    XCTAssertEqual(
      Expression(parse: "(x+3)"),
      .Paren(.Add(.Var("x"), .Num(3.0)))
    )
    XCTAssertEqual(
      Expression(parse: "x"),
      .Var("x")
    )
    XCTAssertEqual(
      Expression(parse: "(x)"),
      .Paren(.Var("x"))
    )
  }

  func testOrderOfOperations() {
    XCTAssertEqual(
      Expression(parse: "1+2×3"),
      .Add(.Num(1), .Mul(.Num(2), .Num(3)))
    )
    XCTAssertEqual(
      Expression(parse: "1+2÷3"),
      .Add(.Num(1), .Div(.Num(2), .Num(3)))
    )
    XCTAssertEqual(
      Expression(parse: "1×2+3"),
      .Add(.Mul(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1+2+3"),
      .Add(.Add(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1+2−3"),
      .Sub(.Add(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1−2−3"),
      .Sub(.Sub(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1−2+3"),
      .Add(.Sub(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1×2×3"),
      .Mul(.Mul(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1÷2÷3"),
      .Div(.Div(.Num(1), .Num(2)), .Num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1+2×3+2"),
      .Add(.Add(.Num(1), .Mul(.Num(2), .Num(3))), .Num(2))
    )
  }

  func testParens() {
    XCTAssertEqual(
      Expression(parse: "(1+2)×2"),
      .Mul(.Paren(.Add(.Num(1.0), .Num(2.0))), .Num(2.0))
    )
    XCTAssertEqual(
      Expression(parse: "(1+2)×(2+1)"),
      .Mul(.Paren(.Add(.Num(1.0), .Num(2.0))), .Paren(.Add(.Num(2.0), .Num(1.0))))
    )
    XCTAssertEqual(
      Expression(parse: "9×(2+1)"),
      .Mul(.Num(9), .Paren(.Add(.Num(2), .Num(1))))
    )
    XCTAssertEqual(
      Expression(parse: "9+(2×1)"),
      .Add(.Num(9), .Paren(.Mul(.Num(2), .Num(1))))
    )
  }
  
}
