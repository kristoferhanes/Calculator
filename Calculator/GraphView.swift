//
//  GraphView.swift
//  Calculator
//
//  Created by Kristofer Hanes on 2015 05 09.
//  Copyright (c) 2015 Kristofer Hanes. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
  func yForX(_ x: CGFloat) -> CGFloat?
  func startProviding()
  func stopProviding()
}

class GraphView: UIView {

  @IBInspectable
  var color: UIColor = UIColor.white { didSet { setNeedsDisplay() } }

  @IBInspectable
  var pointsPerUnit: CGFloat = 1 { didSet { setNeedsDisplay() } }

  fileprivate let axesDrawer = AxesDrawer()
  weak var dataSource: GraphViewDataSource? { didSet { setNeedsDisplay() } }
  var origin: CGPoint? { didSet { setNeedsDisplay() } }
  var precision: CGFloat = 1 {
    didSet {
      if precision < 1 { precision = 1 }
      setNeedsDisplay()
    }
  }

  override func draw(_ rect: CGRect) {
    if origin == nil { origin = CGPoint(x: bounds.midX, y: bounds.midY) }
    axesDrawer.contentScaleFactor = contentScaleFactor
    axesDrawer.color = color
    axesDrawer.highQuality = precision <= 1
    axesDrawer.drawAxesInRect(rect, origin: origin!,
                              pointsPerUnit: pointsPerUnit)
    drawGraph(rect)
  }

  final fileprivate func drawGraph(_ rect: CGRect) {
    var drawing = false
    let origin = self.origin ?? CGPoint(x: bounds.midX, y: bounds.midY)
    let pointsPerUnit = self.pointsPerUnit
    let dataSource = self.dataSource
    dataSource?.startProviding()
    strokePathWithColor(color) { path in
      for x in stride(from: rect.minX, through: rect.maxX, by: self.precision) {
        let point = yForX(x, origin: origin, pointPerUnit: pointsPerUnit,
          dataSource: dataSource).map { y in CGPoint(x: x, y: y) }
        drawing = drawPoint(path, point: point, drawing: drawing)
      }
    }
    dataSource?.stopProviding()
  }

}

private func yForX(_ x: CGFloat, origin: CGPoint, pointPerUnit: CGFloat,
                   dataSource: GraphViewDataSource?) -> CGFloat? {

  return dataSource?.yForX(viewToReal(x, origin: origin.x,
    pointsPerUnit: pointPerUnit)).map { y in
      realToView(-y, origin: origin.y, pointsPerUnit: pointPerUnit) }
}

private func viewToReal(_ coordinate: CGFloat, origin: CGFloat,
                        pointsPerUnit: CGFloat) -> CGFloat {

  return (coordinate - origin) / pointsPerUnit
}

private func realToView(_ coordinate: CGFloat, origin: CGFloat,
                        pointsPerUnit: CGFloat) -> CGFloat {

  return coordinate * pointsPerUnit + origin
}

private func drawPoint(_ path: UIBezierPath, point: CGPoint?,
                       drawing: Bool) -> Bool {

  guard point != nil else { return false }
  lineTo(path, point: point!, drawing: drawing)
  return true
}

private func lineTo(_ path: UIBezierPath, point: CGPoint, drawing: Bool) {
  if drawing { path.addLine(to: point) }
  else { path.move(to: point) }
}

private func strokePathWithColor(_ color: UIColor, f: (UIBezierPath)->Void) {
  UIGraphicsGetCurrentContext()?.saveGState()
  let path = UIBezierPath()
  f(path)
  color.setStroke()
  path.stroke()
  UIGraphicsGetCurrentContext()?.restoreGState()
}
