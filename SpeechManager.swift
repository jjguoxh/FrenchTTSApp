import AVFoundation
import SwiftUI

class SpeechManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    // 预设一段法语文本
    @Published var text: String = "Bonjour, bienvenue dans l'application de synthèse vocale française."
    @Published var rate: Float = 0.5
    @Published var selectedGender: AVSpeechSynthesisVoiceGender = .female
    @Published var isSpeaking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentRange: NSRange?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak() {
        if synthesizer.isSpeaking {
            if synthesizer.isPaused {
                synthesizer.continueSpeaking()
                isPaused = false
                isSpeaking = true
            } else {
                synthesizer.pauseSpeaking(at: .word)
                isPaused = true
                isSpeaking = false // UI uses this to toggle play/pause icon
            }
        } else {
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = rate
            utterance.voice = getVoice(for: selectedGender)
            
            synthesizer.speak(utterance)
            isSpeaking = true
            isPaused = false
        }
    }
    
    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            isPaused = false
            currentRange = nil
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
        isPaused = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        currentRange = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        currentRange = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        currentRange = characterRange
    }
}
