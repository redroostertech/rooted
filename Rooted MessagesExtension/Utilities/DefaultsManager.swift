//
//  DefaultsManager.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 1/30/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation

public class DefaultsManager {
  public static var shared = DefaultsManager()

  private let standard = UserDefaults(suiteName: kGroupName)

  private init() { }

  public func setNilDefault(forKey key: String) {
    standard?.set(nil, forKey: key)
  }
  public func setDefault(withData data: Any, forKey key: String) {
    standard?.set(data, forKey: key)
  }

  public func setDefault(withData data: String, forKey key: String) {
    standard?.set(data, forKey: key)
  }

  public func setDefault(withData data: Int, forKey key: String) {
    standard?.set(data, forKey: key)
  }

  public func setDefault(withData data: Bool, forKey key: String) {
    standard?.set(data, forKey: key)
  }

  public func setDefault(withData data: [String: Any], forKey key: String) {
    standard?.setValue(NSKeyedArchiver.archivedData(withRootObject: data), forKey: key)
  }

  public func setDefault(withData data: Array<Any>, forKey key: String) {
    standard?.set(data, forKey: key)
  }

  public func retrieveAnyDefault(forKey key: String) -> Any? {
    return standard?.object(forKey: key)
  }

  public func retrieveStringDefault(forKey key: String) -> String? {
    return standard?.object(forKey: key) as? String ?? nil
  }

  public func retrieveIntDefault(forKey key: String) -> Int? {
    return standard?.integer(forKey: key)
  }

  public func retrieveBoolDefault(forKey key: String) -> Bool? {
    return standard?.bool(forKey: key)
  }

  public func retrieveDictDefault(forKey key: String) -> [String:Any]? {
    return standard?.dictionary(forKey: key) ?? nil
  }

  public func retrieveArrayDefault(forKey key: String) -> Array<Any>? {
    return standard?.array(forKey: key) ?? nil
  }

  public func deleteDefault(forKey key: String) {
    standard?.removeObject(forKey: key)
  }

}
