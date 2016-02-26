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
    
  func testExprParse() {
    XCTAssertEqual(Expr(parse: "12"), .Num(12.0))
    XCTAssertEqual(Expr(parse: "(12)"), .Num(12.0))
    XCTAssertEqual(Expr(parse: "(1+2)"), .Add(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "(1−2)"), .Sub(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "(1×2)"), .Mul(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "(1÷2)"), .Div(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "sin(23+2)"), .Sin(.Add(.Num(23.0), .Num(2.0))))
    XCTAssertEqual(Expr(parse: "cos(34)"), .Cos(.Num(34.0)))
    XCTAssertEqual(Expr(parse: "(√(5+45))"), .Sqrt(.Add(.Num(5.0), .Num(45.0))))
    XCTAssertEqual(Expr(parse: "(x+3)"), .Add(.Var("x"), .Num(3.0)))
    XCTAssertEqual(Expr(parse: "x"), .Var("x"))
    XCTAssertEqual(Expr(parse: "(x)"), .Var("x"))
  }

  func testOrderOfOperations() {
    XCTAssertEqual(Expr(parse: "1+2*3"), .Add(.Num(1), .Mul(.Num(2), .Num(3))))
  }

}
