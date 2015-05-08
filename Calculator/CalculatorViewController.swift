//
//  ViewController.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {

  @IBOutlet weak var display: UILabel!
  @IBOutlet weak var historyDisplay: UILabel!
  private var userIsTyping = false
  private var brain = CalculatorBrain()

  @IBAction func appendDigit(sender: UIButton) {
    let digit = sender.currentTitle ?? ""
    if userIsTyping {
      appendToDisplay(digit)
    } else {
      setDisplayTo(digit)
      userIsTyping = true
    }
  }

  private func appendToDisplay(s: String) {
    if s != "." || !contains(display.text ?? "", ".") {
      display.text = flatMap(display.text) { x in x + s }
    }
  }

  private func setDisplayTo(s: String) {
    display.text = s
  }

  @IBAction func clear() {
    brain.clear()
    bindModelToView()
    displayValue = 0
  }

  @IBAction func operate(sender: UIButton) {
    if userIsTyping { enter() }
    if let op = sender.currentTitle {
      brain.performOperation(op)
    }
    bindModelToView()
  }

  @IBAction func enter() {
    userIsTyping = false
    if let dv = displayValue {
      brain.pushOperand(dv)
    }
    bindModelToView()
  }

  private func bindModelToView() {
    displayValue = brain.evaluate()
    let description = brain.description
    let suffix = count(description) > 0 ? "=" : " "
    historyDisplay.text = description + suffix
  }

  private var displayValue: Double? {
    get {
      return flatMap(display.text) { x in doubleFromString(x) } }
    set {
      if let nv = newValue {
        display.text = nv == 0 ? "0" : "\(nv)"
      } else {
        display.text = " "
      }
    }
  }

}

