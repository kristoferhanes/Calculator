//
//  GraphView.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 09.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

protocol GraphViewDataSource {
  func yForX(x: Double) -> Double?
}

@IBDesignable
class GraphView: UIView {

  private let axesDrawer = AxesDrawer()

  var dataSource: GraphViewDataSource? { didSet { setNeedsDisplay() } }

  var origin: CGPoint? { didSet { setNeedsDisplay() } }

  var precision: CGFloat = 1 {
    didSet {
      if precision < 1 { precision = 1 }
      setNeedsDisplay()
    }
  }

  @IBInspectable
  var color: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
  
  @IBInspectable
  var pointsPerUnit: CGFloat = 1 { didSet { setNeedsDisplay() } }

  override func drawRect(rect: CGRect) {
    if origin == nil { origin = bounds.center }
    axesDrawer.contentScaleFactor = contentScaleFactor
    axesDrawer.color = color
    axesDrawer.drawAxesInRect(bounds, origin: origin!, pointsPerUnit: pointsPerUnit)
    drawGraph(rect)
  }

  private func drawGraph(rect: CGRect) {
    setStrokeColor(color) {
      let path = UIBezierPath()
      var drawing = false
      var x = rect.minX
      let point = flatMap(self.yForX(x)) { y in CGPoint(x: x, y: y) }
      drawing = self.drawPoint(path, point: point, drawing: drawing)
      while true {
        x += self.precision
        if x >= rect.maxX { break }
        let point = flatMap(self.yForX(x)) { y in CGPoint(x: x, y: y) }
        drawing = self.drawPoint(path, point: point, drawing: drawing)
      }
      path.stroke()
    }
  }

  func drawPoint(path: UIBezierPath, point: CGPoint?, drawing: Bool) -> Bool {
    if point == nil { return false }
    lineTo(path, point: CGPoint(x: point!.x, y: point!.y), drawing: drawing)
    return true
  }

  func lineTo(path: UIBezierPath, point: CGPoint, drawing: Bool) {
    if drawing { path.addLineToPoint(point) }
    else { path.moveToPoint(point) }
  }

  func setStrokeColor(color: UIColor, f: ()->()) {
    CGContextSaveGState(UIGraphicsGetCurrentContext())
    color.setStroke()
    f()
    CGContextRestoreGState(UIGraphicsGetCurrentContext())
  }

  private func yForX(x: CGFloat) -> CGFloat? {
    if origin == nil { return nil }
    return flatMap(dataSource?.yForX(viewToReal(x, origin: origin!.x))) { y in realToView(-y, origin: origin!.y) }
  }

  private func viewToReal(coordinate: CGFloat, origin: CGFloat) -> Double {
    return (Double(coordinate) - Double(origin)) / Double(pointsPerUnit)
  }

  private func realToView(coordinate: Double, origin: CGFloat) -> CGFloat {
    return CGFloat(coordinate) * pointsPerUnit + origin
  }

}


private extension CGRect {
  var center: CGPoint {
    return CGPoint(x: midX, y: midY)
  }
}