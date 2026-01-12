import SwiftUI
import PDFKit
import Vision

class PDFManager: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var currentPageIndex: Int = 0
    @Published var totalPages: Int = 0
    @Published var isRecognizing: Bool = false
    
    // 加载 PDF 文件
    func loadPDF(from url: URL) {
        if let document = PDFDocument(url: url) {
            self.pdfDocument = document
            self.totalPages = document.pageCount
            self.currentPageIndex = 0
        }
    }
    
    // 获取当前页面对象
    var currentPage: PDFPage? {
        guard let document = pdfDocument, currentPageIndex < totalPages else { return nil }
        return document.page(at: currentPageIndex)
    }
    
    // 下一页
    func nextPage() {
        if currentPageIndex < totalPages - 1 {
            currentPageIndex += 1
        }
    }
    
    // 上一页
    func prevPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }
    
    // OCR 识别当前页面文本
    func recognizeText(completion: @escaping (String) -> Void) {
        guard let page = currentPage else {
            completion("")
            return
        }
        
        isRecognizing = true
        
        // 在后台线程执行 OCR
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 1. 将 PDFPage 转换为 CGImage
            guard let cgImage = self?.convertPDFPageToImage(page) else {
                DispatchQueue.main.async {
                    self?.isRecognizing = false
                    completion("无法将页面转换为图像")
                }
                return
            }
            
            // 2. 创建 Vision 请求
            let request = VNRecognizeTextRequest { request, error in
                defer {
                    DispatchQueue.main.async {
                        self?.isRecognizing = false
                    }
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion("OCR 错误: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async {
                        completion("")
                    }
                    return
                }
                
                // 3. 提取文本
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                DispatchQueue.main.async {
                    completion(recognizedText)
                }
            }
            
            // 设置识别语言为法语
            request.recognitionLanguages = ["fr-FR"]
            request.recognitionLevel = .accurate
            
            // 3. 执行请求
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self?.isRecognizing = false
                    completion("OCR 执行失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 辅助方法：将 PDFPage 转为 CGImage
    private func convertPDFPageToImage(_ page: PDFPage) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return image.cgImage
    }
}
