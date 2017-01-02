//
//  PDFUtilities - Tools for working with PDFs
//  PDFUtilities.swift
//
//  Created by Ben Bahrenburg
//  Copyright © 2016 bencoding.com. All rights reserved.
//

import UIKit

open class PDFUtilities {
    
    public struct PDFDocumentPasswordInfo {
        var userPassword: String? = nil
        var ownerPassword: String? = nil
        
        public init(userPassword: String, ownerPassword: String) {
            self.userPassword = userPassword
            self.ownerPassword = ownerPassword
        }
        
        public init(password: String) {
            self.userPassword = password
        }
        
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
    
    class open func convertPageToImage(page: CGPDFPage) -> UIImage {
        let pageRect = page.getBoxRect(CGPDFBox.mediaBox)
        
        UIGraphicsBeginImageContext(pageRect.size)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.interpolationQuality = .high
        
        // Draw existing page
        ctx!.saveGState()
        ctx!.scaleBy(x: 1, y: -1)
        ctx!.translateBy(x: 0, y: -(pageRect.size.height))
        ctx!.drawPDFPage(page)
        ctx!.restoreGState()
        
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return backgroundImage!
    }
    
    class open func hasPassword(fileURL: URL) throws -> Bool {
        return hasPassword(data: try Data(contentsOf: fileURL))
    }
    
    class open func hasPassword(data: Data) -> Bool {
        return autoreleasepool { () -> Bool in
            let dataProvider = CGDataProvider(data: data as CFData)
            if let provider = dataProvider {
                if let pdf = CGPDFDocument(provider) {
                    if pdf.isUnlocked == false || pdf.isEncrypted {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    class open func isValidPDF(data: Data) -> Bool {
        return autoreleasepool { () -> Bool in
            if let provider = CGDataProvider(data: data as CFData) {
                if let pdf = CGPDFDocument(provider) {
                    if pdf.isUnlocked == false || pdf.isEncrypted {
                        return true
                    }
                    return pdf.numberOfPages > 0
                }
            }
            
            return false
        }
    }
    
    class open func isValidPDF(fileURL: URL) throws -> Bool {
        return isValidPDF(data: try Data(contentsOf: fileURL))
    }

    class open func canUnlock(fileURL: URL, password: String) throws -> Bool {
        return try canUnlock(fileURL: fileURL, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func canUnlock(data: Data, password: String) -> Bool {
        return try canUnlock(data: data, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func canUnlock(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo) throws -> Bool {
        return canUnlock(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func canUnlock(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo) -> Bool {
        return autoreleasepool { () -> Bool in
            let pdf = CGPDFDocument(CGDataProvider(data: data as CFData)!)
            guard pdf?.isEncrypted == true else { return true }
            guard pdf?.unlockWithPassword("") == false else { return true }
            
            if let userPassword = documentPasswordInfo.userPassword {
                if let cPasswordString = userPassword.cString(using: String.Encoding.utf8) {
                    if (pdf?.unlockWithPassword(cPasswordString))! {
                        return true
                    }
                }
            }
            if let ownerPassword = documentPasswordInfo.ownerPassword {
                if let cPasswordString = ownerPassword.cString(using: String.Encoding.utf8) {
                    if (pdf?.unlockWithPassword(cPasswordString))! {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    class open func unlock(data: Data, password: String? = nil) -> CGPDFDocument? {
        return unlock(data: data, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func unlock(pdf: CGPDFDocument, password: String? = nil) -> CGPDFDocument? {
        return unlock(pdf: pdf, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func unlock(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> CGPDFDocument? {
        let pdf = CGPDFDocument(CGDataProvider(data: data as CFData)!)
        
        guard documentPasswordInfo != nil else { return pdf }
        
        return unlock(pdf: pdf!, documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func unlock(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> CGPDFDocument? {
        
        guard documentPasswordInfo != nil else { return pdf }
        guard pdf.isEncrypted == true else { return pdf }
        guard pdf.unlockWithPassword("") == false else { return pdf }
        
        if let userPassword = documentPasswordInfo?.userPassword {
            if let cPasswordString = userPassword.cString(using: String.Encoding.utf8) {
                if (pdf.unlockWithPassword(cPasswordString)) {
                    return pdf
                }
            }
        }
        if let ownerPassword = documentPasswordInfo?.ownerPassword {
            if let cPasswordString = ownerPassword.cString(using: String.Encoding.utf8) {
                if (pdf.unlockWithPassword(cPasswordString)) {
                    return pdf
                }
            }
        }
        
        return nil
    }
    
    class open func convertPdfToData(pdf: CGPDFDocument, password: String? = nil) -> Data {
        return convertPdfToData(pdf: pdf, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func convertPdfToData(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> Data {
        let data = NSMutableData()
        
        autoreleasepool {
            let pageCount = pdf.numberOfPages
            let options = (documentPasswordInfo != nil) ? documentPasswordInfo?.toInfo() : nil
            
            UIGraphicsBeginPDFContextToData(data, .zero, options)
            
            for index in 1...pageCount {
                
                let page = pdf.page(at: index)
                let pageRect = page?.getBoxRect(CGPDFBox.mediaBox)
                
                
                UIGraphicsBeginPDFPageWithInfo(pageRect!, nil)
                let ctx = UIGraphicsGetCurrentContext()
                ctx?.interpolationQuality = .high
                // Draw existing page
                ctx!.saveGState()
                ctx!.scaleBy(x: 1, y: -1)
                ctx!.translateBy(x: 0, y: -(pageRect?.size.height)!)
                ctx!.drawPDFPage(page!)
                ctx!.restoreGState()
                
            }
            
            UIGraphicsEndPDFContext()
        }
        return data as Data
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
        if let provider = CGDataProvider(data: data as CFData) {
            if let pdf = CGPDFDocument(provider) {
                return convertPdfToData(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
            }
        }
        return nil
    }
    
    class open func removePassword(fileURL: URL, password: String) throws -> Data? {
        return try removePassword(fileURL: fileURL, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func removePassword(data: Data, password: String) -> Data? {
        return removePassword(data: data, documentPasswordInfo: PDFDocumentPasswordInfo(password: password))
    }
    
    class open func removePassword(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo) throws -> Data? {
        return try removePassword(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func removePassword(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo) -> Data? {
        if let pdf = unlock(data: data, documentPasswordInfo: documentPasswordInfo) {
            return convertPdfToData(pdf: pdf, documentPasswordInfo: nil)
        }
        return nil
    }
    
    class open func convertPDFToImages(fileURL: URL, password: String? = nil) throws -> [UIImage]? {
        return try convertPDFToImages(fileURL: fileURL, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func convertPDFToImages(data: Data, password: String? = nil) -> [UIImage]? {
        return convertPDFToImages(data: data, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func convertPDFToImages(pdf: CGPDFDocument, password: String? = nil) -> [UIImage]? {
        return convertPDFToImages(pdf: pdf, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)))
    }
    
    class open func convertPDFToImages(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) throws -> [UIImage]? {
        return try convertPDFToImages(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func convertPDFToImages(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> [UIImage]? {
        if let provider = CGDataProvider(data: data as CFData) {
            if let pdf = CGPDFDocument(provider) {
                return convertPDFToImages(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
            }
        }
        return nil
    }
    
    class open func convertPDFToImages(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> [UIImage]? {
        var output = [UIImage]()
        let pdf = (documentPasswordInfo != nil) ? unlock(pdf: pdf, documentPasswordInfo: documentPasswordInfo) : pdf
        
        let pageCount = pdf?.numberOfPages ?? 0
        for index in 1...pageCount {
            if let page = pdf?.page(at: index) {
                output.append(convertPageToImage(page: page))
            }
        }
        
        return output
    }
    
    class open func convertImagesToPDF(images: [UIImage], scaleFactor: CGFloat = 1) throws -> Data? {
        return try convertImagesToPDF(images: images, documentPasswordInfo: nil, scaleFactor: scaleFactor)
    }
    
    class open func convertImagesToPDF(images: [UIImage], password: String? = nil, scaleFactor: CGFloat = 1) throws -> Data? {
        return try convertImagesToPDF(images: images, documentPasswordInfo: (password == nil ? nil : PDFDocumentPasswordInfo(password: password!)), scaleFactor: scaleFactor)
    }
    
    class open func convertImagesToPDF(images: [UIImage], documentPasswordInfo: PDFDocumentPasswordInfo? = nil, scaleFactor: CGFloat = 1) throws -> Data? {
        
        guard scaleFactor > 0.0 else {
            return nil
        }
        
        let data = NSMutableData()
        let pageCount = images.count - 1
        
        autoreleasepool {
            let options = (documentPasswordInfo != nil) ? documentPasswordInfo?.toInfo() : nil
            UIGraphicsBeginPDFContextToData(data, .zero, options)
            
            for index in 0...pageCount {
                let bounds = CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: images[index].size.width * scaleFactor,
                        height: images[index].size.height * scaleFactor
                    )
                )
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                images[index].draw(in: bounds)
            }
            UIGraphicsEndPDFContext()
        }
        
        return data as Data
    }
    
}
