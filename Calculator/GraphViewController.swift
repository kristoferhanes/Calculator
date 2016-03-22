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

  private let defaults = NSUserDefaults.standardUserDefaults()

  var pointsPerUnit: CGFloat {
    get {
      let ppu = defaults.objectForKey(Constants.PointsPerUnitKey) as? CGFloat
      graphView.pointsPerUnit = ppu ?? Constants.DefaultPointsPerUnit
      return graphView.pointsPerUnit
    }
    set {
      graphView.pointsPerUnit = newValue
      defaults.setObject(graphView.pointsPerUnit,
                         forKey: Constants.PointsPerUnitKey)
    }
  }

  private var origin: CGPoint? {
    get {
      let x = defaults.objectForKey(Constants.OriginXKey) as? CGFloat
      let y = defaults.objectForKey(Constants.OriginYKey) as? CGFloat
      graphView.origin = x.map { x in y.map { y in CGPoint(x: x, y: y) } }
        ?? graphView.origin
      return graphView.origin
    }
    set {
      graphView.origin = newValue
      defaults.setObject(graphView.origin?.x, forKey: Constants.OriginXKey)
      defaults.setObject(graphView.origin?.y, forKey: Constants.OriginYKey)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    graphView.origin = origin
    graphView.pointsPerUnit = pointsPerUnit
  }

  @IBAction func pinch(sender: UIPinchGestureRecognizer) {
    switch sender.state {
    case .Changed:
      graphView.precision = Constants.GesturePrecision
      let location = sender.locationInView(graphView)
      let scale = sender.scale
      pointsPerUnit *= scale
      if let o = origin {
        let x = (o.x - location.x) * scale + location.x
        let y = (o.y - location.y) * scale + location.y
        origin = CGPoint(x: x, y: y)
      }
      sender.scale = 1
    case .Ended:
      graphView.precision = 1
      sender.scale = 1
    default: break
    }
  }

  @IBAction func pan(sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .Changed:
      graphView.precision = Constants.GesturePrecision
      let translation = sender.translationInView(graphView)
      origin?.x += translation.x
      origin?.y += translation.y
      sender.setTranslation(CGPointZero, inView: graphView)
    case .Ended:
      graphView.precision = 1
      sender.setTranslation(CGPointZero, inView: graphView)
    default: break
    }
  }

  @IBAction func tap(sender: UITapGestureRecognizer) {
    switch sender.state {
    case .Ended:
      origin = sender.locationInView(graphView)
    default: break
    }
  }
  
}
