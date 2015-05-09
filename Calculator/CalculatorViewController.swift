//
//  CalculatorViewController.swift
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
      setDisplayTo(flatMap(display.text) { x in x + s })
    }
  }

  private func setDisplayTo(s: String?) {
    display.text = s
  }

  @IBAction func clear() {
    brain.clear()
    brain.clearVariables()
    bindModelToView()
    displayValue = 0
  }

  @IBAction func setVariable(sender: UIButton) {
    if sender.currentTitle == "→M" {
      brain.variableValues["M"] = displayValue
      userIsTyping = false
    }
    bindModelToView()
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
    let suffix = description != "" ? "=" : " "
    historyDisplay.text = description + suffix
  }

  private var displayValue: Double? {
    get { return flatMap(display.text) { x in doubleFromString(x) } }
    set {
      if let nv = newValue {
        display.text = removeDecimalZeroFrom("\(nv)")
      } else {
        display.text = " "
      }
    }
  }
  
}

