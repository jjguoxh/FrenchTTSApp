import SwiftUI
import PDFKit

struct PDFPageView: UIViewRepresentable {
    let page: PDFPage?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .systemGray6
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = page {
            // 创建一个新的临时文档来只显示这一页，或者直接设置 document 并跳转
            // 为了简单且符合"单页预览"的需求，我们可以直接让 PDFView 显示这一个页面
            // 但 PDFView 需要一个 Document。
            // 更好的方式是 PDFManager 传递 Document 和 PageIndex，这里绑定
            
            // 方案 B: 直接绘制页面。但 PDFView 更好。
            // 如果 PDFManager 里的 pdfDocument 没变，只是 pageIndex 变了。
            // 我们可以让 PDFPageView 接收 document 和 index。
            
            if let document = page.document {
                if pdfView.document != document {
                    pdfView.document = document
                }
                // 跳转到指定页面
                if pdfView.currentPage != page {
                    pdfView.go(to: page)
                }
            }
        } else {
            pdfView.document = nil
        }
    }
}
