import SwiftUI
import PDFKit

struct PDFPageView: NSViewRepresentable {
    let page: PDFPage?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .controlBackgroundColor
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        if let page = page {
            if let document = page.document {
                if pdfView.document != document {
                    pdfView.document = document
                }
                if pdfView.currentPage != page {
                    pdfView.go(to: page)
                }
            }
        } else {
            pdfView.document = nil
        }
    }
}
