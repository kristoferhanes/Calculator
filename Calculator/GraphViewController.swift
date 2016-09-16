//
//  GraphViewController.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 09.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {

  struct Constants {
    static let OriginXKey = "GraphViewController.origin.x"
    static let OriginYKey = "GraphViewController.origin.y"
    static let PointsPerUnitKey = "GraphViewController.pointsPerUnit"
    static let DefaultPointsPerUnit: CGFloat = 10
    static let GesturePrecision: CGFloat = 2
  }

  var dataSource: GraphViewDataSource?

  @IBOutlet weak var graphView: GraphView! {
    didSet { graphView.dataSource = dataSource }
  }

  fileprivate let defaults = UserDefaults.standard

  var pointsPerUnit: CGFloat {
    get {
      let ppu = defaults.object(forKey: Constants.PointsPerUnitKey) as? CGFloat
      graphView.pointsPerUnit = ppu ?? Constants.DefaultPointsPerUnit
      return graphView.pointsPerUnit
    }
    set {
      graphView.pointsPerUnit = newValue
      defaults.set(graphView.pointsPerUnit,
                         forKey: Constants.PointsPerUnitKey)
    }
  }

  fileprivate var origin: CGPoint? {
    get {
      let x = defaults.object(forKey: Constants.OriginXKey) as? CGFloat
      let y = defaults.object(forKey: Constants.OriginYKey) as? CGFloat
      graphView.origin = x.map { x in y.map { y in CGPoint(x: x, y: y) } }
        ?? graphView.origin
      return graphView.origin
    }
    set {
      graphView.origin = newValue
      defaults.set(graphView.origin?.x, forKey: Constants.OriginXKey)
      defaults.set(graphView.origin?.y, forKey: Constants.OriginYKey)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    graphView.origin = origin
    graphView.pointsPerUnit = pointsPerUnit
  }

  @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
    switch sender.state {
    case .changed:
      graphView.precision = Constants.GesturePrecision
      let location = sender.location(in: graphView)
      let scale = sender.scale
      pointsPerUnit *= scale
      if let o = origin {
        let x = (o.x - location.x) * scale + location.x
        let y = (o.y - location.y) * scale + location.y
        origin = CGPoint(x: x, y: y)
      }
      sender.scale = 1
    case .ended:
      graphView.precision = 1
      sender.scale = 1
    default: break
    }
  }

  @IBAction func pan(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .changed:
      graphView.precision = Constants.GesturePrecision
      let translation = sender.translation(in: graphView)
      origin?.x += translation.x
      origin?.y += translation.y
      sender.setTranslation(CGPoint.zero, in: graphView)
    case .ended:
      graphView.precision = 1
      sender.setTranslation(CGPoint.zero, in: graphView)
    default: break
    }
  }

  @IBAction func tap(_ sender: UITapGestureRecognizer) {
    switch sender.state {
    case .ended:
      origin = sender.location(in: graphView)
    default: break
    }
  }
  
}
