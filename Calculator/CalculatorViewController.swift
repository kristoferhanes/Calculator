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
    static let CalculatorProgramKey = "CalculatorViewController.brain.program"
  }

  private enum SegueIdentifier: String {
    case ShowGraph = "ShowGraph"
  }

  @IBOutlet weak var display: UILabel!

  @IBOutlet weak var historyDisplay: UILabel!
  private var userIsTyping = false
  private let brain = CalculatorBrain()
  private var oldVariableValues: CalculatorBrain.VariablesType?

  @IBAction func appendDigit(sender: UIButton) {
    guard let digit = sender.currentTitle else { return }
    if userIsTyping { appendToDisplay(digit) }
    else {
      display.text = digit
      userIsTyping = true
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    brain.program = readCalculatorProgramFromDefaults() ?? []
    bindModelToView()
    _ = (splitViewController?.viewControllers[1])
      .flatMap(graphViewController)
      .map(configGraphViewController)
  }

  private let defaults = NSUserDefaults.standardUserDefaults()

  private func readCalculatorProgramFromDefaults() -> CalculatorBrain.PropertyList? {
    return defaults.objectForKey(Constants.CalculatorProgramKey)
  }

  private func saveToDefaults(program: CalculatorBrain.PropertyList) {
    defaults.setObject(program, forKey: Constants.CalculatorProgramKey)
  }

  private func appendToDisplay(s: String) {
    if s != "." || !(display.text ?? "").characters.contains(".") {
      display.text = display.text.map { $0 + s }
    }
  }

  @IBAction func clear() {
    brain.clear()
    saveToDefaults(brain.program)
    bindModelToView()
    displayValue = 0
  }

  @IBAction func clearAll() {
    brain.clearVariables()
    clear()
  }

  @IBAction func setVariable(sender: UIButton) {
    if sender.currentTitle == Constants.SetMemoryButtonTitle {
      brain.variableValues[Constants.MemoryVariableName] = displayValue
      userIsTyping = false
    }
    saveToDefaults(brain.program)
    bindModelToView()
  }

  @IBAction func operate(sender: UIButton) {
    if userIsTyping { enter() }
    _ = sender.currentTitle.map { brain.performOperation($0) }
    saveToDefaults(brain.program)
    bindModelToView()
  }

  @IBAction func enter() {
    userIsTyping = false
    _ = displayValue.map { brain.pushOperand($0) }
    saveToDefaults(brain.program)
    bindModelToView()
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    guard let id = segue.identifier.flatMap(SegueIdentifier.init)
      else { fatalError("Invalid segue indentifier \(segue.identifier).") }
    guard let gvc = graphViewController(segue.destinationViewController)
      where id == .ShowGraph
      else { return }
    configGraphViewController(gvc)
  }

  private func graphViewController(someObject: AnyObject) -> GraphViewController? {
    let vc = someObject as? UIViewController
    let vvc = (vc as? UINavigationController)?.visibleViewController
    return vvc as? GraphViewController ?? vc as? GraphViewController
  }

  private func configGraphViewController(gvc: GraphViewController) {

    func removeSurroundingWhitespace(s: String) -> String {
      let whitespaceCharSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
      return s.stringByTrimmingCharactersInSet(whitespaceCharSet)
    }

    func lastExpression(expressionsString: String) -> String {
      let expressions = expressionsString.componentsSeparatedByString(",")
      return expressions.last.map(removeSurroundingWhitespace) ?? ""
    }

    gvc.dataSource = self
    gvc.title = lastExpression(brain.description)
  }

  private func bindModelToView() {
    displayValue = brain.evaluate()
    let description = brain.description
    let suffix = description != "" ? "=" : " "
    historyDisplay.text = description + suffix
  }

  private var displayValue: Double? {
    get { return display.text.flatMap { Double($0) } }
    set {
      if let nv = newValue { display.text = "\(nv)".removeDecimalZero() }
      else { display.text = " " }
    }
  }

}

extension CalculatorViewController: GraphViewDataSource {

  func yForX(x: CGFloat) -> CGFloat? {
    brain.variableValues[Constants.MemoryVariableName] = Double(x)
    return brain.evaluate().map { CGFloat($0) }
  }

  func startProviding() {
    oldVariableValues = brain.variableValues
  }

  func stopProviding() {
    guard let ovv = oldVariableValues else { return }
    brain.variableValues = ovv
  }

}
