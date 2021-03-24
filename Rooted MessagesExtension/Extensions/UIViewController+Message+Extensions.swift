import UIKit

public struct NavigationBarButtonViewModel {
  var title: String
  var tintColor: UIColor = .white
  var action: Selector?
  var image: NavigationBarButtonImageViewModel?
  var target: Any?
  var navigationBarAlignment: Int = 0
  var origin: CGPoint = .zero
  var size: CGSize = .zero
  var hAlignment: UIButton.ContentHorizontalAlignment = .center
}

public struct NavigationBarButtonImageViewModel {
  var imageString: String
  var edgeInsets: UIEdgeInsets = .zero
}

public extension UIViewController {
  static var identifier: String {
    return String(describing: self)
  }

  @objc
  func setupSearchbarTextfield(searchBar: UISearchBar?, text: String) {
    
    guard let searchBar = searchBar else { return }

    // TODO: - Consider adding a toolbar on keyboard that displays `DONE` or `CANCEL`
    searchBar.placeholder = text
    setupSearchbarTextfield(searchBar: searchBar)
  }

  func setupSearchbarTextfield(searchBar: UISearchBar?) {

    guard let searchBar = searchBar else { return }

    if let delegate = self as? UISearchBarDelegate {
      searchBar.delegate = delegate
    }

    if let textField = searchBar.value(forKey: "searchField") as? UITextField {
      textField.backgroundColor = .white
      let backgroundView = textField.subviews.first
      if #available(iOS 11.0, *) {
        backgroundView?.backgroundColor = UIColor.white.withAlphaComponent(1)
        backgroundView?.subviews.forEach({ $0.removeFromSuperview() })
      }
      backgroundView?.layer.cornerRadius = 10.5
      backgroundView?.layer.masksToBounds = true
    }
  }

  func hideNavigationBarHairline() {
    self.navigationController?.navigationBar.shadowImage = UIImage()
  }

  func setupNavigationBar(backgroundColor: UIColor,
                          tintColor: UIColor,
                          text: String = "") {
    updateNavigationBar(backgroundColor: backgroundColor,
                        tintColor: tintColor,
                        text: text)
  }

  private func updateNavigationBar(backgroundColor: UIColor,
                                   tintColor: UIColor,
                                   text: String = "") {
    if let navigationcontroller = self.navigationController {
      navigationcontroller.navigationBar.isTranslucent = true
      navigationcontroller.navigationBar.barTintColor = backgroundColor
      navigationcontroller.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: tintColor]
      updateNavigationBar(title: text)
    }
  }

  func updateNavigationBar(title: String) {
    if (self.navigationController != nil) {
      self.navigationItem.title = title
    }
  }

  func updateBackButton(color: UIColor) {
    navigationController?.navigationBar.tintColor = color

  }

  func setBackNavigationButton(_ target: Any?, selector: Selector, textColor: UIColor = .darkText) {
    // TODO: - Create a configuration model for the ContentView of the UIButton component
    let navigationBarButtonImageViewModel = NavigationBarButtonImageViewModel(imageString: kBackText.lowercased(), edgeInsets: UIEdgeInsets(top: .zero, left: -7.0, bottom: .zero, right: -6.0))
    let navigationBarButtonViewModel = NavigationBarButtonViewModel(title: kBackText, tintColor: textColor, action: selector, image: navigationBarButtonImageViewModel, target: target, navigationBarAlignment: 1, origin: .zero, size: CGSize(width: 75, height: 32), hAlignment: .left)
    let _ = setupNavigationBarButton(viewModel: navigationBarButtonViewModel)
  }

  func setupNavigationBarButton(viewModel: NavigationBarButtonViewModel) -> UIBarButtonItem? {
    let button = setupNavigationButton(viewModel: viewModel)
    return updateNavigationBar(withButton: button, side: viewModel.navigationBarAlignment)
  }

  func setupNavigationButton(viewModel: NavigationBarButtonViewModel) -> UIButton? {
    // Create UIButton with configuration from view model
    var button = UIButton(frame: CGRect(origin: viewModel.origin, size: viewModel.size))
    button.accessibilityIdentifier = viewModel.title
    button.setTitle(viewModel.title, for: .normal)
    button.tintColor = viewModel.tintColor
    button.setTitleColor(viewModel.tintColor, for: .normal)
    button.contentHorizontalAlignment = viewModel.hAlignment

    // Check if image is available
    if let imgViewModel = viewModel.image {
      button = update(button: button, viewModel: imgViewModel)
    }

    if let action = viewModel.action {
      button.addTarget(viewModel.target, action: action, for: .touchUpInside)
    }

    return button
  }

  func update(button: UIButton, viewModel: NavigationBarButtonImageViewModel) -> UIButton {
    let img = UIImage(named: viewModel.imageString.lowercased())
    button.setImage(img, for: .normal)
    button.imageEdgeInsets = viewModel.edgeInsets
    // .. add more configuration
    return button
  }

  func setupNavigationBarButton(title: String, tintColor: UIColor, action: Selector?, image: String? = nil, target: Any?, side: Int = 0) -> UIBarButtonItem? {
    let button = UIButton(type: .system)
    button.frame = CGRect(x: 0.0, y: 0.0, width: 50, height: 32)
    button.accessibilityIdentifier = title.lowercased()

    // TODO: - Add edge insets configuration here
    if let imageString = image, let img = UIImage(named: imageString.lowercased())  {
      button.setImage(img, for: .normal)
    }

    button.setTitle(title, for: .normal)
    button.setTitleColor(tintColor, for: .normal)
    button.tintColor = tintColor

    if let act = action {
      button.addTarget(target, action: act, for: .touchUpInside)
    }
    return updateNavigationBar(withButton: button, side: side)
  }

  func updateNavigationBar(withButton button: UIButton?, side: Int) -> UIBarButtonItem? {
    if let btn = button, (self.navigationController != nil) {
      let barButton = UIBarButtonItem(customView: btn)
      if side == 0 {
        if
          let rightBarButtonItems = self.navigationItem.rightBarButtonItems,
          rightBarButtonItems.count > 0 {
          self.navigationItem.rightBarButtonItems?.append(barButton)
        } else {
          self.navigationItem.rightBarButtonItem = barButton
        }
      }
      if side == 1 {
        self.navigationItem.leftBarButtonItem = barButton
        if
          let leftBarButtonItems = self.navigationItem.leftBarButtonItems,
          leftBarButtonItems.count > 0 {
          self.navigationItem.leftBarButtonItems?.append(barButton)
        } else {
          self.navigationItem.leftBarButtonItem = barButton
        }
      }
      return barButton
    }
    return nil
  }

  func removeNavigationBarButton() {
    self.navigationItem.rightBarButtonItem = nil
  }

  func showToast(message : String) {
    let toastLabel = UILabel(frame: CGRect(x: 16, y: self.view.frame.size.height-150, width: self.view.frame.size.width - 32, height: 70))
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    toastLabel.textColor = UIColor.white
    toastLabel.textAlignment = .center;
    toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
    toastLabel.text = message
    toastLabel.alpha = 1.0
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds  =  true
    toastLabel.numberOfLines = 2
    toastLabel.adjustsFontSizeToFitWidth = true
    self.view.addSubview(toastLabel)
    UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
      toastLabel.alpha = 0.0
    }, completion: {(isCompleted) in
      toastLabel.removeFromSuperview()
    })
  }
}
