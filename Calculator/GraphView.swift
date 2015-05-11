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
  func startProviding()
  func stopProviding()
}

@IBDesignable
class GraphView: UIView {

  @IBInspectable
  var color: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }

  @IBInspectable
  var pointsPerUnit: CGFloat = 1 { didSet { setNeedsDisplay() } }
  
  private let axesDrawer = AxesDrawer()
  var dataSource: GraphViewDataSource? { didSet { setNeedsDisplay() } }
  var origin: CGPoint? { didSet { setNeedsDisplay() } }
  var precision: CGFloat = 1 {
    didSet {
      if precision < 1 { precision = 1 }
      setNeedsDisplay()
    }
  }

  override func drawRect(rect: CGRect) {
    if origin == nil { origin = CGPoint(x: bounds.midX, y: bounds.midY) }
    axesDrawer.contentScaleFactor = contentScaleFactor
    axesDrawer.color = color
    axesDrawer.drawAxesInRect(bounds, origin: origin!, pointsPerUnit: pointsPerUnit)
    drawGraph(rect)
  }

  private func drawGraph(rect: CGRect) {
    dataSource?.startProviding()
    strokePathWithColor(color) { path in
      var drawing = false
      for var x = rect.minX; x <= rect.maxX + self.precision; x += self.precision {
        let point = flatMap(self.yForX(x)) { y in CGPoint(x: x, y: y) }
        drawing = drawPoint(path, point, drawing)
      }
    }
    dataSource?.stopProviding()
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

private func drawPoint(path: UIBezierPath, point: CGPoint?, drawing: Bool) -> Bool {
  if point == nil { return false }
  lineTo(path, point!, drawing)
  return true
}

private func lineTo(path: UIBezierPath, point: CGPoint, drawing: Bool) {
  if drawing { path.addLineToPoint(point) }
  else { path.moveToPoint(point) }
}

private func strokePathWithColor(color: UIColor, f: (UIBezierPath)->Void) {
  CGContextSaveGState(UIGraphicsGetCurrentContext())
  let path = UIBezierPath()
  f(path)
  color.setStroke()
  path.stroke()
  CGContextRestoreGState(UIGraphicsGetCurrentContext())
}
