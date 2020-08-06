//
//  EPContact.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 13/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts

open class EPContact: NSObject, TokenSearchable {
    
    open var firstName: String
    open var lastName: String
    open var company: String
    open var thumbnailProfileImage: UIImage?
    open var profileImage: UIImage?
    open var birthday: Date?
    open var birthdayString: String?
    open var contactId: String?
    open var phoneNumbers = [(phoneNumber: String, phoneLabel: String)]()
    open var emails = [(email: String, emailLabel: String )]()
    open var data: CNContact
    open var selectedPhoneNumber: (phoneNumber: String, phoneLabel: String)?
	
    public init (contact: CNContact) {
        data = contact
        firstName = contact.givenName
        lastName = contact.familyName
        company = contact.organizationName
        contactId = contact.identifier
        
        if let thumbnailImageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data:thumbnailImageData)
        }
        
        if let imageData = contact.imageData {
            profileImage = UIImage(data:imageData)
        }
        
        if let birthdayDate = contact.birthday {
            
            birthday = Calendar(identifier: Calendar.Identifier.gregorian).date(from: birthdayDate)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = EPGlobalConstants.Strings.birdtdayDateFormat
            //Example Date Formats:  Oct 4, Sep 18, Mar 9
            birthdayString = dateFormatter.string(from: birthday!)
        }
        
		for phoneNumber in contact.phoneNumbers {
            		var phoneLabel = "phone"
            		if let label = phoneNumber.label {
            		    phoneLabel = label
            		}
			let phone = phoneNumber.value.stringValue
			
			phoneNumbers.append((phone,phoneLabel))
		}
		
		for emailAddress in contact.emailAddresses {
			guard let emailLabel = emailAddress.label else { continue }
			let email = emailAddress.value as String
			
			emails.append((email,emailLabel))
		}
    }
	
    open func displayName() -> String {
        return firstName + " " + lastName
    }
    
    open func contactInitials() -> String {
        var initials = String()
		
		if let firstNameFirstChar = firstName.first {
			initials.append(firstNameFirstChar)
		}
		
		if let lastNameFirstChar = lastName.first {
			initials.append(lastNameFirstChar)
		}
		
        return initials
    }

  public var displayString: String {
    return self.displayName()
  }

  public func contains(token: String) -> Bool {
    return self.firstName.lowercased().contains(token.lowercased()) || self.lastName.lowercased().contains(token.lowercased()) || self.company.lowercased().contains(token.lowercased())
  }

  public var id_fier: NSObject {
    return self as NSObject
  }

  public static func == (lhs: EPContact, rhs: EPContact) -> Bool {
    return lhs.firstName.lowercased() == rhs.firstName.lowercased() && lhs.lastName.lowercased() == rhs.lastName.lowercased() && lhs.contactId?.lowercased() == rhs.contactId?.lowercased()
  }

  public var dictionaryRep: [String: Any] {
    var email = ""
    if self.emails.count > 0 {
      email = self.emails[0].email
    }
    return [
      "firstName": self.firstName,
      "lastName": self.lastName,
      "email": email,
      "phone": self.selectedPhoneNumber?.phoneNumber ?? ""
    ]
  }
}
