import UIKit

extension UITextField {
    func addLeftPadding(withWidth width: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0,
                                           y: 0,
                                           width: width,
                                           height: self.bounds.height))
        self.leftView = padding
        self.leftViewMode = .always
    }

    func addRightPadding(withWidth width: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0,
                                           y: 0,
                                           width: width,
                                           height: self.bounds.height))
        self.rightView = padding
        self.rightViewMode = .always
    }

    public func addHorizontalLine(_ sender: UITextField) {
        let horizontalLine = UIView(frame: CGRect(x: sender.frame.origin.x , y: sender.frame.maxY - 5, width: sender.frame.width, height: 1))
        horizontalLine.backgroundColor = .black
        horizontalLine.layer.zPosition = 1000
        sender.addSubview(horizontalLine)

        print("Size of UIElement \(sender)")
        print(sender.frame.width)
    }

    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
}
