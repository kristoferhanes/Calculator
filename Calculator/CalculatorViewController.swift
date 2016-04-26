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
    static let CalculatorExpressionKey = "CalculatorViewController.calculator.expression"
    static let CalculatorVariablesKey = "CalculatorViewController.calculator.variables"
  }

  private enum SegueIdentifier: String {
    case ShowGraph = "ShowGraph"
  }

  @IBOutlet weak var displayLabel: RoundedLabel!
  @IBOutlet weak var expressionLabel: RoundedLabel!

  private var oldVariableValues: [String:Double]?

  private var calculator = Calculator() {
    didSet {
      bindModelToView()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    loadExpressionFromDefaults()
    guard let vc = (splitViewController?.viewControllers[1]).flatMap(graphViewController)
      else { return }
    configGraphViewController(vc)
    calculator.variables["π"] = M_PI
  }

  private let defaults = NSUserDefaults.standardUserDefaults()

  private func loadExpressionFromDefaults() {
    if let expression = defaults.objectForKey(Constants.CalculatorExpressionKey) as? String {
      calculator.expression = expression
    }
    if let variables = defaults.objectForKey(Constants.CalculatorVariablesKey) as? [String:Double] {
      calculator.variables = variables
    }
  }

  private func saveCalculatorToDefaults() {
    defaults.setObject(calculator.expression, forKey: Constants.CalculatorExpressionKey)
    defaults.setObject(calculator.variables, forKey: Constants.CalculatorVariablesKey)
  }

  @IBAction func delete() {
    guard let expression = expressionLabel.text else { return }
    expressionLabel.text = String(expression.characters.dropLast())
    calculator.expression = expressionLabel.text
    saveCalculatorToDefaults()
  }

  @IBAction func appendCharacter(sender: UIButton) {
    guard let title = sender.currentTitle else { return }
    let expression = expressionLabel.text ?? ""
    expressionLabel.text = expression + title
    calculator.expression = expressionLabel.text
    saveCalculatorToDefaults()
  }

  @IBAction func clear() {
    calculator.clear()
    displayValue = nil
    saveCalculatorToDefaults()
  }

  @IBAction func clearAll() {
    calculator.clearAll()
    clear()
  }

  @IBAction func setVariable(sender: UIButton) {
    if sender.currentTitle == Constants.SetMemoryButtonTitle {
      calculator.variables[Constants.MemoryVariableName] = displayValue
      saveCalculatorToDefaults()
    }
  }

  @IBAction func evalute() {
    displayValue = calculator.value
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
    gvc.dataSource = self
    gvc.title = calculator.expression
  }

  private func bindModelToView() {
    expressionLabel.text = calculator.expression
    displayValue = calculator.value
  }

  private var displayValue: Double? {
    get {
      return displayLabel.text.flatMap { Double($0) }
    }
    set {
      func removeDecimalZero(str: String) -> String {
        guard str.characters.count > 1 else { return str }
        let end = str.startIndex.advancedBy(str.characters.count-2)
        return str.substringFromIndex(end) == ".0" ? str[str.startIndex..<end] : str
      }

      if let nv = newValue {
        displayLabel.text = removeDecimalZero("\(nv)")
      } else {
        displayLabel.text = " "
      }
    }
  }

}

extension CalculatorViewController: GraphViewDataSource {

  func yForX(x: CGFloat) -> CGFloat? {
    calculator.variables[Constants.MemoryVariableName] = Double(x)
    return calculator.value.map { CGFloat($0) }
  }

  func startProviding() {
    oldVariableValues = calculator.variables
  }

  func stopProviding() {
    guard let ovv = oldVariableValues else { return }
    calculator.variables = ovv
  }
  
}
