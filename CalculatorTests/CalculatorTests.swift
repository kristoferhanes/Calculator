//
//  CalculatorTests.swift
//  CalculatorTests
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import XCTest
@testable import Calculator

class CalculatorTests: XCTestCase {

  func testExpressionParse() {
    XCTAssertEqual(
      Expression(parse: "12"),
      .num(12.0)
    )
    XCTAssertEqual(
      Expression(parse: "(12)"),
      .paren(.num(12.0))
    )
    XCTAssertEqual(
      Expression(parse: "(1+2)"),
      .paren(.add(.num(1.0), .num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(1−2)"),
      .paren(.sub(.num(1.0), .num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(1×2)"),
      .paren(.mul(.num(1.0), .num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(1÷2)"),
      .paren(.div(.num(1.0), .num(2.0)))
    )
    XCTAssertEqual(
      Expression(parse: "sin(23+2)"),
      .sin(.paren(.add(.num(23.0), .num(2.0))))
    )
    XCTAssertEqual(
      Expression(parse: "cos(34)"),
      .cos(.paren(.num(34.0)))
    )
    XCTAssertEqual(
      Expression(parse: "(√(5+45))"),
      .paren(.sqrt(.paren(.add(.num(5.0), .num(45.0)))))
    )
    XCTAssertEqual(
      Expression(parse: "(x+3)"),
      .paren(.add(.var("x"), .num(3.0)))
    )
    XCTAssertEqual(
      Expression(parse: "x"),
      .var("x")
    )
    XCTAssertEqual(
      Expression(parse: "(x)"),
      .paren(.var("x"))
    )
  }

  func testOrderOfOperations() {
    XCTAssertEqual(
      Expression(parse: "1+2×3"),
      .add(.num(1), .mul(.num(2), .num(3)))
    )
    XCTAssertEqual(
      Expression(parse: "1+2÷3"),
      .add(.num(1), .div(.num(2), .num(3)))
    )
    XCTAssertEqual(
      Expression(parse: "1×2+3"),
      .add(.mul(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1+2+3"),
      .add(.add(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1+2−3"),
      .sub(.add(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1−2−3"),
      .sub(.sub(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1−2+3"),
      .add(.sub(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1×2×3"),
      .mul(.mul(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1÷2÷3"),
      .div(.div(.num(1), .num(2)), .num(3))
    )
    XCTAssertEqual(
      Expression(parse: "1+2×3+2"),
      .add(.add(.num(1), .mul(.num(2), .num(3))), .num(2))
    )
  }

  func testParens() {
    XCTAssertEqual(
      Expression(parse: "(1+2)×2"),
      .mul(.paren(.add(.num(1.0), .num(2.0))), .num(2.0))
    )
    XCTAssertEqual(
      Expression(parse: "(1+2)×(2+1)"),
      .mul(.paren(.add(.num(1.0), .num(2.0))), .paren(.add(.num(2.0), .num(1.0))))
    )
    XCTAssertEqual(
      Expression(parse: "9×(2+1)"),
      .mul(.num(9), .paren(.add(.num(2), .num(1))))
    )
    XCTAssertEqual(
      Expression(parse: "9+(2×1)"),
      .add(.num(9), .paren(.mul(.num(2), .num(1))))
    )
  }
  
}
