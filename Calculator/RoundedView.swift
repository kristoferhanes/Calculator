//
//  RoundedView.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2016 02 28.
//  Copyright © 2016 Kristofer Hanes. All rights reserved.
//

import UIKit

class RoundedView: UIView {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    layer.cornerRadius = 5.0
    clipsToBounds = true
  }

}
