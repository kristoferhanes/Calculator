//
//  ViewController.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var display: UILabel!
  private var userIsTyping = false
  private var brain = CalculatorBrain()

  @IBAction func appendDigit(sender: UIButton) {
    let digit = sender.currentTitle ?? ""
    if userIsTyping {
      display.text = flatMap(display.text) { x in x + digit }
    } else {
      display.text = digit
      userIsTyping = true
    }
    println("digit = \(digit)")
  }

  @IBAction func operate(sender: UIButton) {
    if userIsTyping { enter() }
    displayValue = flatMap(sender.currentTitle) { x in brain.performOperation(x) }
  }

  @IBAction func enter() {
    userIsTyping = false
    displayValue = flatMap(displayValue) { x in brain.pushOperand(x) }
  }

  private var displayValue: Double? {
    get {
      return flatMap(display.text) { x in NSNumberFormatter().numberFromString(x)?.doubleValue }
    }
    set {
      if let nv = newValue {
        display.text = "\(nv)"
      } else {
        display.text = "Error"
      }
    }
  }
  
}

