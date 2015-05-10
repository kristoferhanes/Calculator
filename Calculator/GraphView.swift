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
}

@IBDesignable
class GraphView: UIView {

  private let axesDrawer = AxesDrawer()

  var dataSource: GraphViewDataSource?

  @IBInspectable
  var color = UIColor.whiteColor()
  @IBInspectable
  var pointsPerUnit: CGFloat = 10.0

  override func drawRect(rect: CGRect) {
    axesDrawer.contentScaleFactor = contentScaleFactor
    axesDrawer.color = color
    axesDrawer.drawAxesInRect(bounds, origin: bounds.center, pointsPerUnit: pointsPerUnit)
    drawGraph()
  }

  private func drawGraph() {
    setStrokeColor(color) {
      let path = UIBezierPath()
      var drawing = true
      var x = self.bounds.minX
      let point = flatMap(self.yForX(x)) { y in CGPoint(x: x, y: y) }
      drawing = self.drawPoint(path, point: point, drawing: drawing)
      while true {
        x += 1 / self.contentScaleFactor
        if x >= self.bounds.maxX { break }
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
    return flatMap(dataSource?.yForX((x-bounds.midX) / pointsPerUnit)) { y in -y * pointsPerUnit + bounds.midY }
  }

}


extension CGRect {
  var center: CGPoint {
    return CGPoint(x: midX, y: midY)
  }
}