//
//  CalculatorViewController.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {

  private struct Constants {
    static let SetMemoryButtonTitle = "→M"
    static let MemoryVariableName = "M"
    static let ShowGraphSegueID = "ShowGraph"
    static let CalculatorProgramKey = "CalculatorViewController.brain.program"
  }

  @IBOutlet
  weak var display: UILabel!

  @IBOutlet
  weak var historyDisplay: UILabel!
  private var userIsTyping = false
  private var brain = CalculatorBrain()

  @IBAction
  func appendDigit(sender: UIButton) {
    let digit = sender.currentTitle ?? ""
    if userIsTyping {
      appendToDisplay(digit)
    } else {
      display.text = digit
      userIsTyping = true
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    brain.program = getCalculatorProgramFromDefaults() ?? []
    bindModelToView()
    configGraphViewController(graphViewControllerFrom(splitViewController?.viewControllers[1]))
  }

  private let defaults = NSUserDefaults.standardUserDefaults()

  private func getCalculatorProgramFromDefaults() -> CalculatorBrain.PropertyList? {
    return defaults.objectForKey(Constants.CalculatorProgramKey)
  }

  private func setCalculatorProgramFromDefaults(program: CalculatorBrain.PropertyList) {
    defaults.setObject(program, forKey: Constants.CalculatorProgramKey)
  }

  private func appendToDisplay(s: String) {
    if s != "." || !contains(display.text ?? "", ".") {
      display.text = flatMap(display.text) { x in x + s }
    }
  }

  @IBAction func clear() {
    brain.clear()
    setCalculatorProgramFromDefaults(brain.program)
    bindModelToView()
    displayValue = 0
  }

  @IBAction func clearAll() {
    brain.clearVariables()
    clear()
  }


  @IBAction
  func setVariable(sender: UIButton) {
    if sender.currentTitle == Constants.SetMemoryButtonTitle {
      brain.variableValues[Constants.MemoryVariableName
        ] = displayValue
      userIsTyping = false
    }
    setCalculatorProgramFromDefaults(brain.program)
    bindModelToView()
  }

  @IBAction
  func operate(sender: UIButton) {
    if userIsTyping { enter() }
    if let op = sender.currentTitle {
      brain.performOperation(op)
    }
    setCalculatorProgramFromDefaults(brain.program)
    bindModelToView()
  }

  @IBAction
  func enter() {
    userIsTyping = false
    if let dv = displayValue {
      brain.pushOperand(dv)
    }
    setCalculatorProgramFromDefaults(brain.program)
    bindModelToView()
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    switch segue.identifier ?? "" {
    case Constants.ShowGraphSegueID:
      configGraphViewController(graphViewControllerFrom(segue.destinationViewController))
    default: break
    }
  }

  private func graphViewControllerFrom(someObject: AnyObject?) -> GraphViewController? {
    let vc = someObject as? UIViewController
    let vvc = (vc as? UINavigationController)?.visibleViewController
    return vvc as? GraphViewController ?? vc as? GraphViewController
  }

  private func configGraphViewController(gvc: GraphViewController?) {
    gvc?.dataSource = self
    gvc?.title = lastExpression(brain.description)
  }

  private func lastExpression(expressionsString: String) -> String {
    let expressions = expressionsString.componentsSeparatedByString(",")
    return expressions.isEmpty ? "" : removeSurroundingWhitespace(expressions.last!)
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


extension CalculatorViewController: GraphViewControllerDataSource {

  func yForX(x: Double) -> Double? {
    let oldValue = brain.variableValues[Constants.MemoryVariableName]
    brain.variableValues[Constants.MemoryVariableName] = x
    let result = brain.evaluate()
    brain.variableValues[Constants.MemoryVariableName] = oldValue
    return result
  }

}


private func removeSurroundingWhitespace(s: String) -> String {
  return s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
}
