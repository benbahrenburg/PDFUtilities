//
//  PDFUtilities - Tools for working with PDFs
//  PDFUtilities.swift
//
//  Created by Ben Bahrenburg
//  Copyright © 2016 bencoding.com. All rights reserved.
//

import UIKit

/**
 
 Utilities to make working with PDFs bearable
 
 */
open class PDFUtilities {
    
    class open func getPDFDocument(fileURL: URL) throws -> CGPDFDocument? {
        return getPDFDocument(data: try Data(contentsOf: fileURL))
    }
    
    class open func getPDFDocument(data: Data) -> CGPDFDocument? {
        let dataProvider = CGDataProvider(data: data as CFData)
        if let provider = dataProvider {
            if let pdf = CGPDFDocument(provider) {
                return pdf
            }
        }
        return nil
    }
    
    class open func hasPassword(fileURL: URL) throws -> Bool {
        return hasPassword(data: try Data(contentsOf: fileURL))
    }
    
    class open func hasPassword(data: Data) -> Bool {
        if let pdf = getPDFDocument(data: data) {
            if pdf.isUnlocked == false || pdf.isEncrypted {
                return true
            }
        }
        return false
    }

    class open func hasPassword(pdf: CGPDFDocument) -> Bool {
        if pdf.isUnlocked == false {
            return true
        }
        
        if pdf.isEncrypted {
            if pdf.isUnlocked {
                return false
            }
            return true
        }
        
        return false
    }
    
    class open func isValidPDF(data: Data) -> Bool {
        if let pdf = getPDFDocument(data: data) {
            if hasPassword(pdf: pdf) {
                return true
            }
            return pdf.numberOfPages > 0
        }
        
        return false
    }
    
    class open func isValidPDF(fileURL: URL) throws -> Bool {
        return isValidPDF(data: try Data(contentsOf: fileURL))
    }
    
    class open func isUnlockable(fileURL: URL, password: String) throws -> Bool {
        return try isUnlockable(fileURL: fileURL, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func isUnlockable(data: Data, password: String) -> Bool {
        return isUnlockable(data: data, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func isUnlockable(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo) throws -> Bool {
        return isUnlockable(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func isUnlockable(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo) -> Bool {
        if let pdf = getPDFDocument(data: data) {
            return isUnlockable(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
        }
        return false
    }
    
    class open func isUnlockable(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo) -> Bool {
        return autoreleasepool { () -> Bool in
            guard pdf.isEncrypted == true else { return true }
            guard pdf.unlockWithPassword("") == false else { return true }
            
            if let ownerPassword = documentPasswordInfo.ownerPassword {
                if let cPasswordString = ownerPassword.cString(using: String.Encoding.utf8) {
                    if pdf.unlockWithPassword(cPasswordString) {
                        return true
                    }
                }
            }
            
            if let userPassword = documentPasswordInfo.userPassword {
                if let cPasswordString = userPassword.cString(using: String.Encoding.utf8) {
                    if pdf.unlockWithPassword(cPasswordString) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    class open func unlockDocument(data: Data, password: String? = nil) -> CGPDFDocument? {
        return unlockDocument(data: data, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func unlockDocument(pdf: CGPDFDocument, password: String? = nil) -> CGPDFDocument? {
        return unlockDocument(pdf: pdf, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func unlockDocument(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> CGPDFDocument? {
        let pdf = CGPDFDocument(CGDataProvider(data: data as CFData)!)
        
        guard documentPasswordInfo != nil else { return pdf }
        
        return unlockDocument(pdf: pdf!, documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func unlockDocument(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> CGPDFDocument? {
        
        guard documentPasswordInfo != nil else { return pdf }
        guard pdf.isEncrypted == true else { return pdf }
        guard pdf.unlockWithPassword("") == false else { return pdf }
        
        if let ownerPassword = documentPasswordInfo?.ownerPassword {
            if let cPasswordString = ownerPassword.cString(using: String.Encoding.utf8) {
                if (pdf.unlockWithPassword(cPasswordString)) {
                    return pdf
                }
            }
        }
        
        if let userPassword = documentPasswordInfo?.userPassword {
            if let cPasswordString = userPassword.cString(using: String.Encoding.utf8) {
                if (pdf.unlockWithPassword(cPasswordString)) {
                    return pdf
                }
            }
        }
        
        return nil
    }
    
    class open func addPassword(fileURL: URL, password: String) throws -> Data? {
        return try addPassword(fileURL: fileURL, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func addPassword(data: Data, password: String) -> Data? {
        return addPassword(data: data, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func addPassword(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo) throws -> Data? {
        return addPassword(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func addPassword(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo) -> Data? {
        if let pdf = getPDFDocument(data: data) {
            return PDFConverters.pdfToData(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
        }
        return nil
    }
    
    class open func addPassword(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo) -> Data? {
        return PDFConverters.pdfToData(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func removePassword(fileURL: URL, password: String) throws -> Data? {
        return try removePassword(fileURL: fileURL, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func removePassword(data: Data, password: String) -> Data? {
        return removePassword(data: data, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func removePassword(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo) throws -> Data? {
        return removePassword(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func removePassword(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo) -> Data? {
        if let pdf = unlockDocument(data: data, documentPasswordInfo: documentPasswordInfo) {
            return PDFConverters.pdfToData(pdf: pdf, documentPasswordInfo: nil)
        }
        return nil
    }
    class open func removePassword(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo) -> Data? {
        return PDFConverters.pdfToData(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
    }
    
}
