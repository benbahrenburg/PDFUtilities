//
//  PDFUtilities - Tools for working with PDFs
//  PDFUtilities.swift
//
//  Created by Ben Bahrenburg on 3/23/16.
//  Copyright © 2016 bencoding.com. All rights reserved.
//

import UIKit

open class PDFUtilities {
    
    class func toDocumentInfo(password: String) -> [String: AnyObject] {
        var info: [String: AnyObject] = [:]
        info[String(kCGPDFContextUserPassword)] = password as AnyObject?
        info[String(kCGPDFContextOwnerPassword)] = password as AnyObject?
        return info
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
    
    class open func hasPassword(fileURL: URL) -> Bool {
        do {
            return hasPassword(data: try Data(contentsOf: fileURL))
        } catch {
            return false
        }
    }
    
    class open func hasPassword(data: Data) -> Bool {
        return autoreleasepool { () -> Bool in
            let dataProvider = CGDataProvider(data: data as CFData)
            if let provider = dataProvider {
                if let pdf = CGPDFDocument(provider) {
                    if pdf.isUnlocked || pdf.isEncrypted {
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
                    if pdf.isUnlocked || pdf.isEncrypted {
                        return true
                    }
                    return pdf.numberOfPages > 0
                }
            }
            
            return false
        }
    }
    
    class open func isValidPDF(fileURL: URL) -> Bool {
        do {
            return isValidPDF(data: try Data(contentsOf: fileURL))
        } catch {
            return false
        }
    }
    
    class open func canUnlock(fileURL: URL, password: String) -> Bool {
        do {
            return canUnlock(data: try Data(contentsOf: fileURL), password: password)
        } catch {
            return false
        }
    }
    
    class open func canUnlock(data: Data, password: String) -> Bool {
        return autoreleasepool { () -> Bool in
            let pdf = CGPDFDocument(CGDataProvider(data: data as CFData)!)
            
            // Try a blank password first, per Apple's Quartz PDF example
            if pdf?.isEncrypted == true &&
                pdf?.unlockWithPassword("") == false {
                // Nope, now let's try the provided password to unlock the PDF
                if let cPasswordString = password.cString(using: String.Encoding.utf8) {
                    if pdf?.unlockWithPassword(cPasswordString) == false {
                        return false
                    }
                }
            }
            return true
        }
    }
    
    class open func unlock(data: Data, password: String? = nil) -> CGPDFDocument? {
        let pdf = CGPDFDocument(CGDataProvider(data: data as CFData)!)
        
        guard password != nil else { return pdf }
        
        return unlock(pdf: pdf!, password: password)
    }
    
    class open func unlock(pdf: CGPDFDocument, password: String? = nil) -> CGPDFDocument? {
        
        guard password != nil else { return pdf }
        
        // Try a blank password first, per Apple's Quartz PDF example
        if pdf.isEncrypted == true &&
            pdf.unlockWithPassword("") == false {
            if let pwd = password {
                // Nope, now let's try the provided password to unlock the PDF
                if let cPasswordString = pwd.cString(using: String.Encoding.utf8) {
                    if pdf.unlockWithPassword(cPasswordString) == true {
                        return pdf
                    }
                }
            }
        }
        return nil
    }
    
    class open func convertPdfToData(pdf: CGPDFDocument, password: String? = nil) -> Data {
        let data = NSMutableData()
        
        autoreleasepool {
            let pageCount = pdf.numberOfPages
            let options = (password != nil) ? self.toDocumentInfo(password: password!) : nil
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
    
    class open func addPassword(fileURL: URL, password: String) -> Data? {
        do {
            return addPassword(data: try Data(contentsOf: fileURL), password: password)
        } catch {
            return nil
        }
    }
    
    class open func addPassword(data: Data, password: String) -> Data? {
        if let provider = CGDataProvider(data: data as CFData) {
            if let pdf = CGPDFDocument(provider) {
                return convertPdfToData(pdf: pdf, password: password)
            }
        }
        return nil
    }
    
    class open func removePassword(fileURL: URL, password: String) throws -> Data? {
        return try removePassword(data: try Data(contentsOf: fileURL), password: password)
    }
    
    class open func removePassword(data: Data, password: String) throws -> Data? {
        if let pdf = unlock(data: data, password: password) {
            return convertPdfToData(pdf: pdf)
        }
        return nil
    }
    
    class open func convertPDFToImages(fileURL: URL, password: String? = nil) throws -> [UIImage]? {
        return try convertPDFToImages(data: try Data(contentsOf: fileURL), password: password)
    }
    
    class open func convertPDFToImages(data: Data, password: String? = nil) throws -> [UIImage]? {
        if let provider = CGDataProvider(data: data as CFData) {
            if let pdf = CGPDFDocument(provider) {
                return convertPDFToImages(pdf: pdf, password: password)
            }
        }
        return nil
    }
    
    class open func convertPDFToImages(pdf: CGPDFDocument, password: String? = nil) -> [UIImage]? {
        var output = [UIImage]()
        let pdf = (password != nil) ? unlock(pdf: pdf, password: password) : pdf
        
        let pageCount = pdf?.numberOfPages ?? 0
        for index in 1...pageCount {
            if let page = pdf?.page(at: index) {
                output.append(convertPageToImage(page: page))
            }
        }
        
        return output
    }
    
    class open func convertImagesToPDF(images: [UIImage], password: String? = nil, scaleFactor: CGFloat = 1) throws -> Data? {
        
        guard scaleFactor > 0.0 else {
            return nil
        }
  
        let data = NSMutableData()
        let pageCount = images.count - 1
        
        autoreleasepool {
            let options = (password != nil) ? self.toDocumentInfo(password: password!) : nil
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
