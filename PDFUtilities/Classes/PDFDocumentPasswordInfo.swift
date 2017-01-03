//
//  PDFUtilities - Tools for working with PDFs
//  PDFDocumentPasswordInfo.swift
//
//  Created by Ben Bahrenburg
//  Copyright © 2016 bencoding.com. All rights reserved.
//

import Foundation

/**
 
 PDF Password Struct, used to unlock or add a password to a PDF
 
 Provides the ability to set the User and/or Owner Passwords
 
 If you init using just a single password the User password will be used.
 
 */
public struct PDFDocumentPasswordInfo {
    
    /// User Password (optional)
    var userPassword: String? = nil
    
    /// Owner Password (optional)
    var ownerPassword: String? = nil
    
    /**
     Creates a new instance of the PDFDocumentPasswordInfo object
     
     - Parameter userPassword: The User password
     - Parameter ownerPassword: The Owner password
     */
    public init(userPassword: String, ownerPassword: String) {
        self.userPassword = userPassword
        self.ownerPassword = ownerPassword
    }
    
    /**
     Creates a new instance of the PDFDocumentPasswordInfo object
     
     - Parameter password: The password provided will be used as the User Password
     */
    public init(password: String) {
        self.userPassword = password
    }
    
    /**
     The toInfo method is used to create meta data for unlocking or locking pdfs.
     
     - Parameter forKey: The key used to return a stored value
     - Returns: An Array of items used when locking or unlocking PDFs.
     */
    func toInfo() -> [AnyHashable : Any] {
        var info: [AnyHashable : Any] = [:]
        if let userPassword = self.userPassword {
            info[String(kCGPDFContextUserPassword)] = userPassword as AnyObject?
        }
        if let ownerPassword = self.ownerPassword {
            info[String(kCGPDFContextOwnerPassword)] = ownerPassword as AnyObject?
        }
        
        return info
    }
}
    
