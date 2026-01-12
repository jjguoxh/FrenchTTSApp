import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 文本输入区域 (最大化，移除所有内边距)
                TextEditor(text: $speechManager.text)
                    .background(Color(.systemGray6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                // 2. 底部紧凑控制区
                HStack(alignment: .center, spacing: 12) {
                    // 播放/停止按钮
                    Button(action: {
                        if speechManager.isSpeaking {
                            speechManager.stop()
                        } else {
                            speechManager.speak()
                        }
                    }) {
                        Image(systemName: speechManager.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 48, height: 48) // 稍微加大一点
                            .foregroundColor(speechManager.isSpeaking ? .red : .blue)
                    }
                    
                    // 右侧控制面板 (语速 + 性别)
                    VStack(spacing: 8) {
                        // 语速滑杆
                        HStack(spacing: 8) {
                            Image(systemName: "tortoise.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $speechManager.rate, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
                            
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
                    .frame(maxWidth: .infinity) // 确保右侧面板占满剩余空间
                }
                .padding(.horizontal, 12) // 减少左右边距
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground)) // 稍微深一点的背景区分底部
            }
            .navigationBarHidden(true)
            .onTapGesture {
                // 点击空白处收起键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
