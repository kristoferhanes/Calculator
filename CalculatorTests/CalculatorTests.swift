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
    
  func testExpr() {
    XCTAssertEqual(Expr(parse: "(1+2)"), .Add(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "(1−2)"), .Sub(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "(1×2)"), .Mul(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "(1÷2)"), .Div(.Num(1.0), .Num(2.0)))
    XCTAssertEqual(Expr(parse: "sin(23)"), .Sin(.Num(23.0)))
    XCTAssertEqual(Expr(parse: "cos(34)"), .Cos(.Num(34.0)))
  }

}
