//
//  MasterFirstSplitViewController.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 11.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

class MasterFirstSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    self.delegate = self
  }

  func splitViewController(splitViewController: UISplitViewController,
    collapseSecondaryViewController: UIViewController,
    ontoPrimaryViewController: UIViewController) -> Bool {
    return true
  }

}
