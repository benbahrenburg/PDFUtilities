//
//  PDFUtilities - Tools for working with PDFs
//  PDFConverters.swift
//
//  Created by Ben Bahrenburg
//  Copyright © 2016 bencoding.com. All rights reserved.
//

import UIKit

/**
 
 Utilities to convert to and from PDFs
 
 */
open class PDFConverters {

    class open func pdfPageToImage(page: CGPDFPage) -> UIImage? {
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
        
        return backgroundImage
    }
    
    class open func pdfToData(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> Data {
        
        return autoreleasepool { () -> Data in
            let data = NSMutableData()
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
            
            return data as Data
        }
        
    }
    
    class open func imagesToPDF(images: [UIImage], scaleFactor: CGFloat = 1) throws -> Data? {
        return try imagesToPDF(images: images, scaleFactor: scaleFactor, documentPasswordInfo: nil)
    }
    
    class open func imagesToPDF(images: [UIImage], scaleFactor: CGFloat = 1, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) throws -> Data? {
        
        guard scaleFactor > 0.0 else {
            return nil
        }
        
        return autoreleasepool { () -> Data in
            let data = NSMutableData()
            let pageCount = images.count - 1
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
            return data as Data
        }
        
    }
        
    class open func pdfToImages(fileURL: URL, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) throws -> [UIImage]? {
        return pdfToImages(data: try Data(contentsOf: fileURL), documentPasswordInfo: documentPasswordInfo)
    }
    
    class open func pdfToImages(data: Data, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> [UIImage]? {
        if let pdf = PDFUtilities.getPDFDocument(data: data) {
            return pdfToImages(pdf: pdf, documentPasswordInfo: documentPasswordInfo)
        }
        return nil
    }
    
    class open func pdfToImages(pdf: CGPDFDocument, documentPasswordInfo: PDFDocumentPasswordInfo? = nil) -> [UIImage]? {
        let pdfSource = (documentPasswordInfo != nil) ? PDFUtilities.unlockDocument(pdf: pdf, documentPasswordInfo: documentPasswordInfo!) : pdf
        
        guard let pdf = pdfSource else {
            return nil
        }
        
        guard pdf.numberOfPages > 0 else {
            return nil
        }
        
        var output = [UIImage]()
        
        for index in 0...pdf.numberOfPages {
            if let page = pdf.page(at: index) {
                if let img = pdfPageToImage(page: page) {
                    output.append(img)
                }
            }
        }
        
        return output
    }
}
