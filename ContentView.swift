import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var pdfManager = PDFManager()
    @State private var showFileImporter = false
    
    private var pageBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(pdfManager.currentPageIndex) },
            set: {
                let maxIndex = max(0, pdfManager.totalPages - 1)
                let clamped = max(0, min(Int($0), maxIndex))
                pdfManager.currentPageIndex = clamped
            }
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // 1. PDF 预览区域 (如果已加载 PDF)
                    if pdfManager.pdfDocument != nil {
                        VStack(spacing: 0) {
                            // PDF 顶部工具栏
                            HStack {
                                Button(action: { pdfManager.prevPage() }) {
                                    Image(systemName: "chevron.left")
                                }
                                .disabled(pdfManager.currentPageIndex <= 0)
                                
                                Spacer()
                                Text("页码 \(pdfManager.currentPageIndex + 1) / \(pdfManager.totalPages)")
                                    .font(.caption)
                                Spacer()
                                
                                Button(action: { pdfManager.nextPage() }) {
                                    Image(systemName: "chevron.right")
                                }
                                .disabled(pdfManager.currentPageIndex >= pdfManager.totalPages - 1)
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            
                            // PDF 视图
                            PDFPageView(page: pdfManager.currentPage)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            // OCR 状态提示
                            if pdfManager.isRecognizing {
                                HStack {
                                    ProgressView()
                                    Text("正在识别文本...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(4)
                                .background(Color(.systemBackground))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: pdfManager.currentPageIndex) { _ in
                            pdfManager.scheduleRecognizeText(delay: 0.0) { recognizedText in
                                speechManager.text = recognizedText
                            }
                        }
                        
                        Divider()
                    }
                    
                    // 2. 文本输入区域 (最大化，移除所有内边距)
                    ZStack(alignment: .topTrailing) {
                        HighlightedTextEditor(text: $speechManager.text, highlightedRange: speechManager.currentRange)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // 导入 PDF 按钮 (悬浮在文本框右上角，或者放在底部)
                        // 这里我们放在顶部导航栏或者作为一个悬浮按钮
                        Button(action: { showFileImporter = true }) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title2)
                                .padding(8)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Divider()
                
                // 3. 底部紧凑控制区
                HStack(alignment: .center, spacing: 8) {
                    // 播放/暂停按钮
                    Button(action: {
                        speechManager.speak()
                    }) {
                        Image(systemName: speechManager.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(speechManager.isSpeaking ? .orange : .blue)
                    }
                    
                    // 停止按钮
                    Button(action: {
                        speechManager.stop()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.red)
                    }
                    
                    // 右侧控制面板 (语速 + 性别)
                    VStack(spacing: 8) {
                        // 语速滑杆
                        HStack(spacing: 8) {
                            if pdfManager.totalPages > 0 {
                                Slider(value: pageBinding, in: 0...Double(max(0, pdfManager.totalPages - 1)), step: 1)
                                    .controlSize(.small)
                                    .frame(height: 27)
                                    .frame(width: 150)
                                Text("\(pdfManager.currentPageIndex + 1)/\(pdfManager.totalPages)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Divider()
                            }
                            Image(systemName: "tortoise.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $speechManager.rate, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
                                .controlSize(.small)
                                .frame(height: 27)
                            
                            Image(systemName: "hare.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // 性别选择
                        Picker("选择性别", selection: $speechManager.selectedGender) {
                            Text("女声").tag(AVSpeechSynthesisVoiceGender.female)
                            Text("男声").tag(AVSpeechSynthesisVoiceGender.male)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(height: 48)
                .background(Color(.secondarySystemBackground))
            }
            .navigationBarHidden(true)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
                switch result {
                case .success(let url):
                    // 安全访问受保护的资源
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        pdfManager.loadPDF(from: url)
                        
                        pdfManager.scheduleRecognizeText(delay: 0.0) { recognizedText in
                            speechManager.text = recognizedText
                        }
                    }
                case .failure(let error):
                    print("导入失败: \(error.localizedDescription)")
                }
            }
            .onAppear {
                pdfManager.restoreLastSession()
                if pdfManager.pdfDocument != nil {
                    pdfManager.scheduleRecognizeText(delay: 0.0) { recognizedText in
                        speechManager.text = recognizedText
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HighlightedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var highlightedRange: NSRange?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .title2)
        textView.backgroundColor = UIColor.systemGray6
        textView.isEditable = true
        textView.isScrollEnabled = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .title2), range: fullRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        
        if let range = highlightedRange, range.location != NSNotFound, range.location + range.length <= nsString.length {
            attributed.addAttribute(.backgroundColor, value: UIColor.systemYellow, range: range)
            attributed.addAttribute(.foregroundColor, value: UIColor.black, range: range)
        }
        
        let selectedRange = uiView.selectedRange
        uiView.attributedText = attributed
        uiView.selectedRange = selectedRange
        
        if let range = highlightedRange, range.location != NSNotFound, range.location + range.length <= nsString.length {
            uiView.scrollRangeToVisible(range)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: HighlightedTextEditor
        
        init(_ parent: HighlightedTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
