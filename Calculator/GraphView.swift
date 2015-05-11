//
//  GraphView.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 09.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

protocol GraphViewDataSource {
  func yForX(x: CGFloat) -> CGFloat?
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
    axesDrawer.highQuality = precision <= 1
    axesDrawer.drawAxesInRect(rect, origin: origin!, pointsPerUnit: pointsPerUnit)
    drawGraph(rect)
  }

  private func drawGraph(rect: CGRect) {
    dataSource?.startProviding()
    strokePathWithColor(color) { path in
      var drawing = false
      let precision = self.precision
      let origin = self.origin ?? CGPoint(x: self.bounds.midX, y: self.bounds.midY)
      let pointsPerUnit = self.pointsPerUnit
      let dataSource = self.dataSource
      let maxX = rect.maxX + precision
      for var x = rect.minX; x < maxX; x += precision {
        let point = flatMap(yForX(x, origin, pointsPerUnit, dataSource)) { y in CGPoint(x: x, y: y) }
        drawing = drawPoint(path, point, drawing)
      }
    }
    dataSource?.stopProviding()
  }

}

private func yForX(x: CGFloat, origin: CGPoint, pointPerUnit: CGFloat, dataSource: GraphViewDataSource?) -> CGFloat? {
  return flatMap(dataSource?.yForX(viewToReal(x, origin.x, pointPerUnit))) { y in realToView(-y, origin.y, pointPerUnit) }
}

private func viewToReal(coordinate: CGFloat, origin: CGFloat, pointsPerUnit: CGFloat) -> CGFloat {
  return (coordinate - origin) / pointsPerUnit
}

private func realToView(coordinate: CGFloat, origin: CGFloat, pointsPerUnit: CGFloat) -> CGFloat {
  return coordinate * pointsPerUnit + origin
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
