import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var pdfManager = PDFManager()
    @State private var showFileImporter = false
    
    var body: some View {
        HSplitView {
            // 左侧：PDF 预览与 OCR
            VStack(spacing: 0) {
                if pdfManager.pdfDocument != nil {
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
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // PDF 视图
                    PDFPageView(page: pdfManager.currentPage)
                        .frame(minWidth: 300, minHeight: 400)
                    
                    // OCR 状态提示
                    if pdfManager.isRecognizing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.5)
                            Text("正在识别文本...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(4)
                    }
                } else {
                    VStack {
                        Text("请导入 PDF 文件")
                            .foregroundColor(.secondary)
                        Button("打开文件...") {
                            showFileImporter = true
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 300)
            
            // 右侧：文本编辑与朗读控制
            VStack(spacing: 0) {
                // 文本输入区域
                TextEditor(text: $speechManager.text)
                    .font(.body)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                // 底部控制区
                HStack(spacing: 16) {
                    // 播放控制
                    Button(action: {
                        if speechManager.isSpeaking {
                            speechManager.stop()
                        } else {
                            speechManager.speak()
                        }
                    }) {
                        Image(systemName: speechManager.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(speechManager.isSpeaking ? .red : .blue)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 语速
                        HStack {
                            Text("语速")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $speechManager.rate, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
                                .frame(width: 120)
                        }
                        
                        // 性别
                        Picker("", selection: $speechManager.selectedGender) {
                            Text("女声").tag(AVSpeechSynthesisVoiceGender.female)
                            Text("男声").tag(AVSpeechSynthesisVoiceGender.male)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                    
                    Spacer()
                    
                    // 导入按钮 (放在工具栏也可以，这里放底部方便)
                    Button(action: { showFileImporter = true }) {
                        Label("导入 PDF", systemImage: "doc.text.viewfinder")
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(minWidth: 300)
        }
        .onChange(of: pdfManager.currentPageIndex) { _ in
            pdfManager.recognizeText { recognizedText in
                speechManager.text = recognizedText
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    pdfManager.loadPDF(from: url)
                    pdfManager.recognizeText { recognizedText in
                        speechManager.text = recognizedText
                    }
                }
            case .failure(let error):
                print("导入失败: \(error.localizedDescription)")
            }
        }
    }
}
