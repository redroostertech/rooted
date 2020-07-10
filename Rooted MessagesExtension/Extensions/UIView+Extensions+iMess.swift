//
//  UIView+Additions.swift
//  Gumbo
//
//  Created by Michael Westbrooks on 7/18/18.
//  Copyright © 2018 RedRooster Technologies Inc. All rights reserved.
//

import UIKit

extension UIView {

  static var identifier: String {
    return String(describing: self)
  }

    func loadNib(nibName: String) -> UIView {
        let bundle = Bundle(for: type(of: self))
        //let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    func addGradientLayer(using colors: [CGColor]) {
        applyClipsToBounds(true)
        self.backgroundColor = .clear
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = colors
        //  gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        guard let button = self as? UIButton else {
            self.layer.insertSublayer(gradientLayer,
                                      at: 0)
            return
        }
        button.layer.insertSublayer(gradientLayer,
                                   below: button.imageView?.layer)
    }
    
    func applyBorder(withColor color: UIColor, andThickness width: CGFloat) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
    
    func applyCornerRadius(_ radius: CGFloat = 0.50) {
        applyClipsToBounds(true)
        self.layer.cornerRadius = self.frame.height * radius
    }
    
    func applyClipsToBounds(_ bool: Bool) {
        self.clipsToBounds = bool
    }
    
    public func convertToImage() -> UIImage {
        UIGraphicsBeginImageContext(bounds.size)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    public func applyTopCornerStyle(_ cornerRadius: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: cornerRadius,
                                                        height: cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
    
    public func applyBottomCornerStyle(_ cornerRadius: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: [.bottomLeft, .bottomRight],
                                    cornerRadii: CGSize(width: cornerRadius,
                                                        height: cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }

    enum LayoutDirection {
        case horizontal
        case vertical
    }
    
    @objc func clear() {
        subviews.forEach { (view) in
            view.removeFromSuperview()
        }
    }
    
    public func makeHeightZero() {
        let verticalSpaceConstraint = self.superview!.constraints.filter({(constraint) -> Bool in
            return constraint.secondItem as? UIView == self && constraint.secondAttribute == NSLayoutConstraint.Attribute.bottom
        }).first
        
        let superViewHeightConstraint = self.superview!.constraints.filter({(constraint) -> Bool in
            return constraint.firstAttribute == NSLayoutConstraint.Attribute.height
        }).first
        
        superViewHeightConstraint?.constant -= verticalSpaceConstraint?.constant ?? 0 + self.frame.height
        verticalSpaceConstraint?.constant = 0
        
        let heightConstraint = self.constraints.filter({(constraint) -> Bool in
            return constraint.firstAttribute == NSLayoutConstraint.Attribute.height
        }).first
        if heightConstraint != nil {self.removeConstraint(heightConstraint!)}
        
        let constH = NSLayoutConstraint(item: self,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                        toItem: nil,
                                        attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                                        multiplier: 1, constant: 0)
        
        self.addConstraint(constH)
        self.isHidden = true
    }
    
    public func removeHeightConstraint() {
        let constHt = self.constraints.filter { $0.firstAttribute == .height}.first
        if let htConstFound = constHt {
            self.removeConstraint(htConstFound)
        }
    }
    
    public func setHeightConstraint(constant: CGFloat) {
        removeHeightConstraint()
        let constH = NSLayoutConstraint(item: self,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 1,
                                        constant: constant)
        self.addConstraint(constH)
    }
    
    @objc public func addSubViewWithFillConstraints(_ subView: UIView) {
        addSubview(subView)
        fillConstraintsWithConstants(subView)
    }
    
    public func addSubViewAtCenter(_ subView: UIView) {
        addSubview(subView)
        constraintView(subView, forAttribute: .centerX)
        constraintView(subView, forAttribute: .centerY)
        constraintView(subView, forAttribute: .height)
        constraintView(subView, forAttribute: .width)
    }
    
    public func centerSubView(_ subView: UIView) {
        addSubview(subView)
        constraintView(subView, forAttribute: .centerX)
        constraintView(subView, forAttribute: .centerY)
        constraintView(subView, forAttribute: .height)
    }
    
    func constraintAdjacentSubviews(firstView: UIView,
                                    secondView: UIView,
                                    spacing: CGFloat = 0,
                                    priority: UILayoutPriority = .required,
                                    direction: LayoutDirection) {
        var const = NSLayoutConstraint()
        
        switch direction {
        case .horizontal:
            const = NSLayoutConstraint(item: firstView,
                                       attribute: .trailing,
                                       relatedBy: .equal,
                                       toItem: secondView,
                                       attribute: .leading,
                                       multiplier: 1,
                                       constant: 0)
        case .vertical:
            const = NSLayoutConstraint(item: firstView,
                                       attribute: .bottom,
                                       relatedBy: .equal,
                                       toItem: secondView,
                                       attribute: .top,
                                       multiplier: 1,
                                       constant: 0)
        }
        
        const.priority = priority
        addConstraint(const)
    }
    
    public func fillConstraintsWithConstants(_ target: UIView,
                                             leading: CGFloat = 0,
                                             trailing: CGFloat = 0,
                                             top: CGFloat = 0,
                                             bottom: CGFloat = 0) {
        constraintView(target, forAttribute: .leading, constant: leading)
        constraintView(target, forAttribute: .top, constant: top)
        constraintView(target, forAttribute: .trailing, constant: trailing)
        constraintView(target, forAttribute: .bottom, constant: bottom)
    }
    
    public func constraintView(_ target: UIView,
                               forAttribute attrib: NSLayoutConstraint.Attribute,
                               multiplier: CGFloat = 1,
                               constant: CGFloat = 0,
                               priority: UILayoutPriority = .required ) {
        let constraint = NSLayoutConstraint(item: target,
                                            attribute: attrib,
                                            relatedBy: .equal,
                                            toItem: self,
                                            attribute: attrib,
                                            multiplier: multiplier,
                                            constant: constant)
        constraint.priority = priority
        addConstraint(constraint)
    }
    
    public func removeAllConstraintsInGraph() {
        self.subviews.forEach {(view) in
            view.removeAllConstraintsInGraph()
        }
        self.constraints.forEach { (constraint) in
            self.removeConstraint(constraint)
        }
    }
}

@objc extension UIView {
    public func constraint(_ view: UIView) -> Constraint {
        return Constraint(self, view: view)
    }
    
}

@objc public class Constraint: NSObject {
    let view: UIView
    let superView: UIView
    
    public init(_ superView: UIView, view: UIView) {
        self.view = view
        self.superView = superView
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: Align Top Edges
    
    @discardableResult public func alignTopEdges(by constant: CGFloat, priority: UILayoutPriority) -> Self {
        removeConstraints(onView: view, forAttributes: [.top])
        superView.constraintView(view, forAttribute: .top, constant: constant, priority: priority)
        return self
    }
    
    @objc @discardableResult public func alignTopEdges(by constant: CGFloat) -> Self {
        return alignTopEdges(by: constant, priority: .required)
    }
    
    @objc @discardableResult public func alignTopEdges() -> Self {
        return alignTopEdges(by: 0, priority: .required)
    }
    
    // MARK: Align Bottom Edges
    
    @discardableResult public func alignBottomEdges(by constant: CGFloat, priority: UILayoutPriority) -> Self {
        removeConstraints(onView: view, forAttributes: [.bottom])
        superView.constraintView(view, forAttribute: .bottom, constant: constant, priority: priority)
        return self
    }
    
    @objc @discardableResult public func alignBottomEdges(by constant: CGFloat) -> Self {
        return alignBottomEdges(by: constant, priority: .required)
    }
    
    @objc @discardableResult public func alignBottomEdges() -> Self {
        return alignBottomEdges(by: 0, priority: .required)
    }
    
    // MARK: Align Left Edges
    
    @discardableResult public func alignLeftEdges(by constant: CGFloat, priority: UILayoutPriority) -> Self {
        removeConstraints(onView: view, forAttributes: [.leading])
        superView.constraintView(view, forAttribute: .leading, constant: constant, priority: priority)
        return self
    }
    
    @objc @discardableResult public func alignLeftEdges(by constant: CGFloat) -> Self {
        return alignLeftEdges(by: constant, priority: .required)
    }
    
    @objc @discardableResult public func alignLeftEdges() -> Self {
        return alignLeftEdges(by: 0, priority: .required)
    }
    
    // MARK: Align Right Edges
    
    @discardableResult public func alignRightEdges(by constant: CGFloat, priority: UILayoutPriority) -> Self {
        removeConstraints(onView: view, forAttributes: [.trailing])
        superView.constraintView(view, forAttribute: .trailing, constant: constant, priority: priority)
        return self
    }
    
    @objc @discardableResult public func alignRightEdges(by constant: CGFloat) -> Self {
        return alignRightEdges(by: constant, priority: .required)
    }
    
    @objc @discardableResult public func alignRightEdges() -> Self {
        return alignRightEdges(by: 0, priority: .required)
    }
    
    // MARK: Center
    
    @discardableResult public func center() -> Self {
        return self.centerHorizontally().centerVertically()
    }
    
    @discardableResult public func centerHorizontally() -> Self {
        return centerHorizontally(offset: 0)
    }
    
    @discardableResult public func centerHorizontally(offset: CGFloat) -> Self {
        superView.constraintView(view, forAttribute: .centerX, constant: offset)
        return self
    }
    
    @objc @discardableResult public func centerVertically() -> Self {
        return centerVertically(offset: 0)
    }
    
    @discardableResult public func centerVertically(offset: CGFloat) -> Self {
        superView.constraintView(view, forAttribute: .centerY, constant: offset)
        return self
    }
    
    // MARK: Fit and Fill
    
    @discardableResult public func fill(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) -> Constraint {
        superView.fillConstraintsWithConstants(view, leading: left, trailing: right, top: top, bottom: bottom)
        return Constraint(superView, view: view)
    }
    
    @discardableResult public func fill() -> Constraint {
        return fill(top: 0, bottom: 0, left: 0, right: 0)
    }
    
    @discardableResult public func fitContent() -> Constraint {
        let priority = UILayoutPriority(UILayoutPriority.defaultLow.rawValue + 1.0)
        view.setContentHuggingPriority(priority, for: .horizontal)
        view.setContentHuggingPriority(priority, for: .vertical)
        return Constraint(superView, view: view)
    }
    
    // MARK: Size
    
    @objc @discardableResult public func width(_ constant: CGFloat) -> Constraint {
        return constrain(attribute: .width, to: constant, relatedBy: .equal)
    }
    
    @discardableResult public func minWidth(_ constant: CGFloat) -> Constraint {
        return constrain(attribute: .width, to: constant, relatedBy: .greaterThanOrEqual)
    }
    
    @objc @discardableResult public func height(_ constant: CGFloat) -> Constraint {
        return constrain(attribute: .height, to: constant)
    }
    
    @discardableResult public func minHeight(_ constant: CGFloat) -> Constraint {
        return constrain(attribute: .height, to: constant, relatedBy: .greaterThanOrEqual)
    }
    
    @objc @discardableResult public func heightToWidth(multiplier: CGFloat) -> Self {
        removeConstraints(onView: view, forAttributes: [.height])
        view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier).isActive = true
        return self
    }
    
    @discardableResult public func matchParentWidth() -> Self {
        removeConstraints(onView: view, forAttributes: [.width])
        superView.constraintView(view, forAttribute: .width, constant: 0)
        return self
    }
    
    // MARK: Place Next
    
    @discardableResult public func placeNext(_ nextView: UIView, by constant: CGFloat, priority: UILayoutPriority) -> Constraint {
        superView.constraintAdjacentSubviews(firstView: view, secondView: nextView, spacing: constant, priority: priority, direction: .horizontal)
        return Constraint(superView, view: nextView)
    }
    
    @discardableResult public func placeNext(_ nextView: UIView, priority: UILayoutPriority) -> Constraint {
        return placeNext(nextView, by: 0, priority: priority)
    }
    
    @discardableResult public func placeNext(_ nextView: UIView) -> Constraint {
        return placeNext(nextView, by: 0, priority: .required)
    }
    
    // MARK: Place Above
    
    @discardableResult public func placeAbove(_ lowerView: UIView, by constant: CGFloat, priority: UILayoutPriority) -> Constraint {
        superView.constraintAdjacentSubviews(firstView: view, secondView: lowerView, spacing: constant, priority: priority, direction: .vertical)
        return Constraint(superView, view: lowerView)
    }
    
    @discardableResult public func placeAbove(_ lowerView: UIView) -> Constraint {
        return placeAbove(lowerView, by: 0, priority: .required)
    }
    
    // MARK: Remove Constraints
    
    private func removeConstraints(onView view: UIView, forAttributes: [NSLayoutConstraint.Attribute]) {
        forAttributes.forEach { (attrib) in
            let const = view.constraints.filter {$0.firstAttribute == attrib}
            superView.removeConstraints(const)
        }
    }
    
    // MARK: Internal helpers
    
    private func constrain(attribute: NSLayoutConstraint.Attribute, to value: CGFloat, relatedBy relation: NSLayoutConstraint.Relation = .equal) -> Constraint {
        removeConstraints(onView: view, forAttributes: [attribute])
        view.addConstraint(NSLayoutConstraint(item: view,
                                              attribute: attribute,
                                              relatedBy: relation,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1, constant: value))
        return Constraint(superView, view: view)
    }
}

extension UIView {
    func applyPrimaryGradient() {
        let array: [UIColor] = [.gradientColor1, .gradientColor2, .gradientColor3]
        let colorArray: [CGColor] = array.map { color in
            return color.cgColor
        }
        addGradientLayer(using: colorArray)
    }
}


@IBDesignable
class DesignableView: UIView {
}

extension DesignableView {

  @IBInspectable
  var cornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
    }
  }

  @IBInspectable
  var borderWidth: CGFloat {
    get {
      return layer.borderWidth
    }
    set {
      layer.borderWidth = newValue
    }
  }

  @IBInspectable
  var borderColor: UIColor? {
    get {
      if let color = layer.borderColor {
        return UIColor(cgColor: color)
      }
      return nil
    }
    set {
      if let color = newValue {
        layer.borderColor = color.cgColor
      } else {
        layer.borderColor = nil
      }
    }
  }

  @IBInspectable
  var shadowRadius: CGFloat {
    get {
      return layer.shadowRadius
    }
    set {
      layer.shadowRadius = newValue
    }
  }

  @IBInspectable
  var shadowOpacity: Float {
    get {
      return layer.shadowOpacity
    }
    set {
      layer.shadowOpacity = newValue
    }
  }

  @IBInspectable
  var shadowOffset: CGSize {
    get {
      return layer.shadowOffset
    }
    set {
      layer.shadowOffset = newValue
    }
  }

  @IBInspectable
  var shadowColor: UIColor? {
    get {
      if let color = layer.shadowColor {
        return UIColor(cgColor: color)
      }
      return nil
    }
    set {
      if let color = newValue {
        layer.shadowColor = color.cgColor
      } else {
        layer.shadowColor = nil
      }
    }
  }
}
