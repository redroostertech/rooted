//
//  KeychainManager.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 6/23/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import KeychainSwift

public enum KeychainSwiftInterfaceAccessOptions {
  case accessibleAfterFirstUnlock
  case accessibleAfterFirstUnlockThisDeviceOnly
  case accessibleAlways
  case accessibleAlwaysThisDeviceOnly
  case accessibleWhenPasscodeSetThisDeviceOnly
  case accessibleWhenUnlocked
  case accessibleWhenUnlockedThisDeviceOnly
}

public class KeychainManager: NSObject {
  public static var shared = KeychainManager()

  private var keychain: KeychainSwift!

  private override init() {
    self.keychain = KeychainSwift()
    self.keychain.synchronizable = true
    self.keychain.accessGroup = kKeychainAccessGroupName
  }
}

// MARK: - Save data into keychain
public extension KeychainManager {
  func save(password: String) -> Bool? {
    if keychain.set(password, forKey: "password", withAccess: .accessibleWhenUnlocked) {
      return true
    } else {
      return false
    }
  }

  func setDefault(withData data: String, forKey key: String) -> Bool {
    if keychain.set(data, forKey: key, withAccess: .accessibleWhenUnlocked) {
      return true
    } else {
      return false
    }
  }

  func setDefault(withData dict: [String: Any], forKey key: String) -> Bool {
    let data: Data = NSKeyedArchiver.archivedData(withRootObject: dict)
    if keychain.set(data, forKey: key, withAccess: .accessibleWhenUnlocked) {
      return true
    } else {
      return false
    }
  }

  func setDefault(withData data: Bool, forKey key: String) -> Bool {
    if keychain.set(data, forKey: key, withAccess: .accessibleWhenUnlocked) {
      return true
    } else {
      return false
    }
  }

  func setDefault(withData data: Data, forKey key: String) -> Bool {
    if keychain.set(data, forKey: key, withAccess: .accessibleWhenUnlocked) {
      return true
    } else {
      return false
    }
  }
}

// MARK: - Retrieve data from keychain
public extension KeychainManager {
  func retrievePassword() -> String? {
    return keychain.get("password")
  }

  func retrieveDictDefault(forKey key: String) -> [String: Any]? {
    if let data = keychain.getData(key) {
      return NSKeyedUnarchiver.unarchiveObject(with: data) as? [String : Any]
    } else {
      return nil
    }
  }

  func retrieveStringDefault(forKey key: String) -> String? {
    return keychain.get(key)
  }

  func retrieveBoolDefault(forKey key: String) -> Bool? {
    return keychain.getBool(key)
  }

  func retrieveDataDefault(forKey key: String) -> Data? {
    return keychain.getData(key)
  }
}

// MARK: - Delete data from keychain
public extension KeychainManager {
  func deletePassword() -> Bool {
    return keychain.delete("password")
  }

  func deleteDefault(forKey key: String) -> Bool {
    return keychain.delete(key)
  }
}
