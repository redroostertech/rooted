import Foundation
import UIKit

extension String {
    var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }

    var sdbmhash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(0) {
            Int($1) &+ ($0 << 6) &+ ($0 << 16) - $0
        }
    }

    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }

    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.width)
    }

    func isEmptyTrimmingSpaces() -> Bool {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: " ")).isEmpty
    }

    var parseJSONString: [String: AnyObject]? {
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let jsonData = data {
            do {
                return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject]
            } catch let error as NSError {
                print(error)
            }
            return nil
        }
        return nil
    }

    var isBlank: Bool {
        get {
            let trimmed = trimmingCharacters(in: CharacterSet.whitespaces)
            return trimmed.isEmpty
        }
    }

    //Validate Email

    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil
        } catch {
            return false
        }
    }

    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }

  var isAlphabet: Bool {
      return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
  }

    //validate Password
    var isValidPassword: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[a-zA-Z_0-9\\-_,;.:#+*?=!§$%&/()@]+$", options: .caseInsensitive)
            if(regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil){

                if(self.characters.count>=6 && self.characters.count<=20){
                    return true
                }else{
                    return false
                }
            }else{
                return false
            }
        } catch {
            return false
        }
    }

    //validate Phone Number
    var isPhoneNumber: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSMakeRange(0, self.characters.count))
            if let res = matches.first {
                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == self.characters.count
            } else {
                return false
            }
        } catch {
            return false
        }
    }

    static func className(_ aClass: AnyClass) -> String {
        return NSStringFromClass(aClass).components(separatedBy: ".").last!
    }

    func startsWith(string: String) -> Bool {
        guard let range = range(of: string, options:[.caseInsensitive]) else {
            return false
        }
        return range.lowerBound == startIndex
    }

    func substring(_ from: Int) -> String {
        return self.substring(from: self.index(self.startIndex, offsetBy: from))
    }

    var length: Int {
        return utf16.count
    }

    func equalsIgnoreCase(str:String)->Bool{
        var isEqual:Bool = false
        if(self.caseInsensitiveCompare(str) == ComparisonResult.orderedSame){
            isEqual = true
        }
        return isEqual
    }

  func convertToDate(_ format: CustomDateFormat = .rooted, inTimeZone: String? = nil) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        if inTimeZone == nil {
            dateFormatter.timeZone = .autoupdatingCurrent
        }
        print(dateFormatter.date(from: self))
        return dateFormatter.date(from: self) ?? Date()
    }

    var westernArabicNumeralsOnly: String {
        let pattern = UnicodeScalar("0")..."9"
        return String(unicodeScalars
            .flatMap { pattern ~= $0 ? Character($0) : nil })
    }

  func convertToDictionary() -> [String: Any]? {
    let jsonData = self.data(using: .utf8)!
    let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
    return dictionary as? [String : Any]
  }
}

//  MARK:- Validation
extension NSString {
    //    func isValidUsername() -> Bool {
    //        return (self.length >= 6
    //            && self.length <= 32
    //            && !self.isNumeric())
    //    }
    //
    //    func isValidPassword() -> Bool {
    //        return (self.length >= 8
    //            && self.length <= 20
    //            && self.isFollowingPasswordConstraints())
    //    }
}

/*
 1. getLocalizedTextFor method reads from Localizable.strings
 file of the given module
 2. getTextFor method reads from the ModuleName.strings file
 which should be used when localizable string value are
 same across different targets
 */

extension String {
    //    public static func getLocalizedTextFor(key: String, module: String = DeltaUIKitModule.name) -> String {
    //        return getLocalizedText(key: key, module: module)
    //    }
    //
    //    public static func getTextFor(key: String, module: String = DeltaUIKitModule.name) -> String {
    //        return getText(key: key, module: module)
    //    }
}

extension NSString {
    //    @objc public static func getLocalizedTextFor(key: String, module: String = DeltaUIKitModule.name) -> String {
    //        return getLocalizedText(key: key, module: module)
    //    }
    //
    //    @objc public static func getTextFor(key: String, module: String = DeltaUIKitModule.name) -> String {
    //        return getText(key: key, module: module)
    //    }
}

//private func getLocalizedText(key: String, module: String) -> String {
//    if let bundle = Bundle(identifier: DeltaUIKitModule.defaultModule.moduleBundleMap.getBundleIdentifier(module: module)) {
//        return bundle.localizedString(forKey: key, value: "", table: nil)
//    }
//    return key
//}
//
//private func getText(key: String, module: String) -> String {
//    if let bundle = Bundle(identifier: DeltaUIKitModule.defaultModule.moduleBundleMap.getBundleIdentifier(module: module)) {
//        return bundle.localizedString(forKey: key, value: "", table: module)
//    }
//    return key
//}


