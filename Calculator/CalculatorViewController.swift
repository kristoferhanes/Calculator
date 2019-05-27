//
//  CalculatorViewController.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 06.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {

  fileprivate struct Constants {
    static let SetMemoryButtonTitle = "→M"
    static let MemoryVariableName = "M"
    static let CalculatorExpressionKey = "CalculatorViewController.calculator.expression"
    static let CalculatorVariablesKey = "CalculatorViewController.calculator.variables"
  }

  fileprivate enum SegueIdentifier: String {
    case ShowGraph = "ShowGraph"
  }

  @IBOutlet weak var displayLabel: RoundedLabel!
  @IBOutlet weak var expressionLabel: RoundedLabel!

  fileprivate var oldVariableValues: [String:Double]?

  fileprivate var calculator = Calculator() {
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
    calculator.variables["π"] = Double.pi
  }

  fileprivate let defaults = UserDefaults.standard

  fileprivate func loadExpressionFromDefaults() {
    if let expression = defaults.object(forKey: Constants.CalculatorExpressionKey) as? String {
      calculator.expression = expression
    }
    if let variables = defaults.object(forKey: Constants.CalculatorVariablesKey) as? [String:Double] {
      calculator.variables = variables
    }
  }

  fileprivate func saveCalculatorToDefaults() {
    defaults.set(calculator.expression, forKey: Constants.CalculatorExpressionKey)
    defaults.set(calculator.variables, forKey: Constants.CalculatorVariablesKey)
  }

  @IBAction func delete() {
    guard let expression = expressionLabel.text else { return }
    expressionLabel.text = String(expression.dropLast())
    calculator.expression = expressionLabel.text
    saveCalculatorToDefaults()
  }

  @IBAction func appendCharacter(_ sender: UIButton) {
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

  @IBAction func setVariable(_ sender: UIButton) {
    if sender.currentTitle == Constants.SetMemoryButtonTitle {
      calculator.variables[Constants.MemoryVariableName] = displayValue
      saveCalculatorToDefaults()
    }
  }

  @IBAction func evalute() {
    displayValue = calculator.value
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let id = segue.identifier.flatMap(SegueIdentifier.init)
        else { fatalError("Invalid segue indentifier \(segue.identifier ?? "nil").") }
    guard let gvc = graphViewController(segue.destination)
      , id == .ShowGraph
      else { return }
    configGraphViewController(gvc)
  }

  fileprivate func graphViewController(_ someObject: AnyObject) -> GraphViewController? {
    let vc = someObject as? UIViewController
    let vvc = (vc as? UINavigationController)?.visibleViewController
    return vvc as? GraphViewController ?? vc as? GraphViewController
  }

  fileprivate func configGraphViewController(_ gvc: GraphViewController) {
    gvc.dataSource = self
    gvc.title = calculator.expression
  }

  fileprivate func bindModelToView() {
    expressionLabel.text = calculator.expression
    displayValue = calculator.value
  }

  fileprivate var displayValue: Double? {
    get {
      return displayLabel.text.flatMap { Double($0) }
    }
    set {
      func removeDecimalZero(_ str: String) -> String {
        return str.suffix(2) == ".0" ? String(str.dropLast(2)) : str
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

  func yForX(_ x: CGFloat) -> CGFloat? {
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
