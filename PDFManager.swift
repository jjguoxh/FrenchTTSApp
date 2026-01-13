import SwiftUI
import PDFKit
import Vision
import NaturalLanguage
import Foundation

class PDFManager: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var currentPageIndex: Int = 0
    @Published var totalPages: Int = 0
    @Published var isRecognizing: Bool = false
    private var recognizeWorkItem: DispatchWorkItem?
    private(set) var currentURL: URL?
    
    private let kvs = NSUbiquitousKeyValueStore.default
    private let bookmarkKey = "lastPDFBookmark"
    private let pageKey = "lastPDFPageIndex"
    private let localPathKey = "lastLocalPDFPath"
    private let savedFolderName = "SavedPDFs"
    
    // 加载 PDF 文件
    func loadPDF(from url: URL) {
        let localURL = copyToLocalIfNeeded(from: url)
        if let document = PDFDocument(url: localURL) {
            self.pdfDocument = document
            self.totalPages = document.pageCount
            self.currentPageIndex = 0
            self.currentURL = localURL
            persistSession()
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
            persistSession()
        }
    }
    
    // 上一页
    func prevPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            persistSession()
        }
    }
    
    // OCR 识别当前页面文本
    func recognizeText(completion: @escaping (String) -> Void) {
        guard let page = currentPage else {
            completion("")
            return
        }
        
        isRecognizing = true
        let pageIndexAtStart = currentPageIndex
        
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
                    if let strongSelf = self, strongSelf.currentPageIndex == pageIndexAtStart {
                        completion(recognizedText)
                    }
                }
            }
            
            // 设置识别语言优先为简体中文，其次法语（不处理英文）
            request.recognitionLanguages = ["zh-Hans", "fr-FR"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
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
    
    func scheduleRecognizeText(delay: TimeInterval = 1.5, completion: @escaping (String) -> Void) {
        recognizeWorkItem?.cancel()
        isRecognizing = false
        let work = DispatchWorkItem { [weak self] in
            self?.recognizeText(completion: completion)
        }
        recognizeWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    private func persistSession() {
        guard let url = currentURL else { return }
        kvs.set(url.lastPathComponent, forKey: localPathKey)
        kvs.set(Int64(currentPageIndex), forKey: pageKey)
        kvs.synchronize()
    }
    
    func restoreLastSession() {
        kvs.synchronize()
        guard let fileName = kvs.string(forKey: localPathKey) else { return }
        let folderURL = documentsDirectory().appendingPathComponent(savedFolderName, isDirectory: true)
        let fileURL = folderURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let document = PDFDocument(url: fileURL) {
                self.pdfDocument = document
                self.totalPages = document.pageCount
                self.currentURL = fileURL
                var savedPage = Int(kvs.longLong(forKey: pageKey))
                if savedPage < 0 || savedPage >= totalPages { savedPage = 0 }
                self.currentPageIndex = savedPage
            }
        }
    }
    
    // 辅助方法：将 PDFPage 转为 CGImage
    private func convertPDFPageToImage(_ page: PDFPage) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        
        // 为提升中文识别质量，按较高分辨率渲染（限制最大边以防内存过高）
        let maxSide: CGFloat = 2000.0
        let currentMax = max(pageRect.size.width, pageRect.size.height)
        let scale = min(maxSide / currentMax, 2.0)
        let targetSize = CGSize(width: pageRect.size.width * scale, height: pageRect.size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            ctx.cgContext.translateBy(x: 0.0, y: targetSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return image.cgImage
    }
    
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func ensureSavedFolder() -> URL {
        let folderURL = documentsDirectory().appendingPathComponent(savedFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }
    
    private func copyToLocalIfNeeded(from url: URL) -> URL {
        let folderURL = ensureSavedFolder()
        let destURL = folderURL.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: destURL.path) {
            return destURL
        }
        do {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                try FileManager.default.copyItem(at: url, to: destURL)
                return destURL
            } else {
                // 尝试不使用安全作用域直接复制（如来自本地沙盒）
                try FileManager.default.copyItem(at: url, to: destURL)
                return destURL
            }
        } catch {
            // 如果复制失败，退回使用原始 URL
            return url
        }
    }
}
