import AVFoundation
import SwiftUI

class SpeechManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    // 预设一段法语文本
    @Published var text: String = "Bonjour, bienvenue dans l'application de synthèse vocale française."
    @Published var rate: Float = 0.5
    @Published var selectedGender: AVSpeechSynthesisVoiceGender = .female
    @Published var isSpeaking: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak() {
        // 如果正在说话，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = getVoice(for: selectedGender)
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func getVoice(for gender: AVSpeechSynthesisVoiceGender) -> AVSpeechSynthesisVoice? {
        // 获取所有法语语音
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "fr") }
        
        // 尝试寻找匹配性别的语音
        if let match = voices.first(where: { $0.gender == gender }) {
            return match
        }
        
        // 如果找不到特定性别的，就返回任意法语语音，或者默认语音
        return voices.first ?? AVSpeechSynthesisVoice(language: "fr-FR")
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
