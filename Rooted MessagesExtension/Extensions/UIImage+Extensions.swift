import UIKit

public extension UIImage {
  
  static func imageFromColor(_ color: UIColor) -> UIImage {
    let rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    UIGraphicsBeginImageContext(rect.size)
    let context: CGContext = UIGraphicsGetCurrentContext()!
    context.setFillColor(color.cgColor)
    context.fill(rect)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
  }

  func decodedImage() -> UIImage {
    guard let cgImage = cgImage else { return self }
    let size = CGSize(width: cgImage.width, height: cgImage.height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
    guard let decodedImage = context?.makeImage() else { return self }
    return UIImage(cgImage: decodedImage)
  }

  // Rough estimation of how much memory image uses in bytes
  var diskSize: Int {
    guard let cgImage = cgImage else { return 0 }
    return cgImage.bytesPerRow * cgImage.height
  }
  func maskWithColor(color: UIColor) -> UIImage? {
    let maskImage = cgImage!

    let width = size.width
    let height = size.height
    let bounds = CGRect(x: 0, y: 0, width: width, height: height)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

    context.clip(to: bounds, mask: maskImage)
    context.setFillColor(color.cgColor)
    context.fill(bounds)

    if let cgImage = context.makeImage() {
      let coloredImage = UIImage(cgImage: cgImage)
      return coloredImage
    } else {
      return nil
    }
  }

  func resizedImage(newSize: CGSize) -> UIImage {
    guard self.size != newSize else { return self }

    let originRatio = self.size.width / self.size.height
    let newRatio = newSize.width / newSize.height
    var size: CGSize = .zero

    if originRatio < newRatio {
      size.height = newSize.height
      size.width = newSize.height * originRatio
    } else {
      size.width = newSize.width
      size.height = newSize.width / originRatio
    }

    let scale: CGFloat = UIScreen.main.scale
    size.width /= scale
    size.height /= scale
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
  }

  func makeCentrallyAlignedCompositeImage(_ superImposeImage: UIImage, scaleInParts: CGFloat) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
    self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let scale = (floor(scaleInParts / 2))/scaleInParts
    let width = size.width
    let height = size.height
    let compositeImageRect = CGRect(x: width*scale, y: height*scale, width: width/scaleInParts, height: height/scaleInParts)
    superImposeImage.draw(in: compositeImageRect)
    return UIGraphicsGetImageFromCurrentImageContext()!
  }

  var isPortrait:  Bool    { return size.height > size.width }
  var isLandscape: Bool    { return size.width > size.height }
  var breadth:     CGFloat { return min(size.width, size.height) }
  var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
  var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
  var circleMasked: UIImage? {
    UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
    defer { UIGraphicsEndImageContext() }
    guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
    UIBezierPath(ovalIn: breadthRect).addClip()
    UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation).draw(in: breadthRect)
    return UIGraphicsGetImageFromCurrentImageContext()
  }

  func squareImage() -> UIImage {
    let image = self
    let originalWidth  = image.size.width
    let originalHeight = image.size.height
    var x: CGFloat = 0.0
    var y: CGFloat = 0.0
    var edge: CGFloat = 0.0

    if (originalWidth > originalHeight) {
      // landscape
      edge = originalHeight
      x = (originalWidth - edge) / 2.0
      y = 0.0

    } else if (originalHeight > originalWidth) {
      // portrait
      edge = originalWidth
      x = 0.0
      y = (originalHeight - originalWidth) / 2.0
    } else {
      // square
      edge = originalWidth
    }

    let cropSquare = CGRect(x:x, y:y, width:edge, height:edge)

    let imageRef = image.cgImage!.cropping(to: cropSquare)

    return UIImage(cgImage: imageRef!, scale: UIScreen.main.scale, orientation: image.imageOrientation)
  }

  func resize(withWidth newWidth: CGFloat) -> UIImage? {

    let scale = newWidth / self.size.width
    let newHeight = self.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
  }

}
