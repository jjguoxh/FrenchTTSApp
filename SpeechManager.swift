import AVFoundation
import SwiftUI
import NaturalLanguage

class SpeechManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceRanges: [ObjectIdentifier: NSRange] = [:]
    
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
            utteranceRanges.removeAll()
            let utterances = buildUtterances(from: text)
            for (utt, rangeInFullText) in utterances {
                utt.rate = rate
                utteranceRanges[ObjectIdentifier(utt)] = rangeInFullText
                synthesizer.speak(utt)
            }
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
            utteranceRanges.removeAll()
        }
    }
    
    private func getVoice(for gender: AVSpeechSynthesisVoiceGender, languageCode: String) -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let family = languageCode.lowercased().split(separator: "-").first.map(String.init) ?? languageCode.lowercased()
        let familyVoices = all.filter { $0.language.lowercased().hasPrefix(family) }
        if let match = familyVoices.first(where: { $0.gender == gender }) { return match }
        if let anyFamily = familyVoices.first { return anyFamily }
        let exactVoices = all.filter { $0.language.lowercased() == languageCode.lowercased() }
        if let exactMatch = exactVoices.first(where: { $0.gender == gender }) { return exactMatch }
        return exactVoices.first ?? AVSpeechSynthesisVoice(language: languageCode)
    }
    
    private func buildUtterances(from fullText: String) -> [(AVSpeechUtterance, NSRange)] {
        var results: [(AVSpeechUtterance, NSRange)] = []
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = fullText
        
        tagger.enumerateTags(in: fullText.startIndex..<fullText.endIndex, unit: .sentence, scheme: .language, options: []) { tag, range in
            let sentence = String(fullText[range])
            let nsRange = NSRange(range, in: fullText)
            
            let nlCode = (tag?.rawValue ?? "")
            let speechCode = mapToSpeechLanguageCode(nlCode: nlCode, fallback: sentenceContainsChinese(sentence) ? "zh-CN" : "fr-FR")
            
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = getVoice(for: selectedGender, languageCode: speechCode)
            results.append((utterance, nsRange))
            return true
        }
        
        if results.isEmpty {
            let defaultUtt = AVSpeechUtterance(string: fullText)
            defaultUtt.voice = getVoice(for: selectedGender, languageCode: "fr-FR")
            results.append((defaultUtt, NSRange(location: 0, length: (fullText as NSString).length)))
        }
        return results
    }
    
    private func mapToSpeechLanguageCode(nlCode: String, fallback: String) -> String {
        switch nlCode.lowercased() {
        case "fr", "fr-fr": return "fr-FR"
        case "zh", "zh-hans": return "zh-CN"
        case "en", "en-us": return "en-US"
        default: return fallback
        }
    }
    
    private func sentenceContainsChinese(_ s: String) -> Bool {
        for scalar in s.unicodeScalars {
            if (0x4E00...0x9FFF).contains(Int(scalar.value)) { return true }
        }
        return false
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
        utteranceRanges.removeValue(forKey: ObjectIdentifier(utterance))
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        currentRange = nil
        utteranceRanges.removeValue(forKey: ObjectIdentifier(utterance))
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
        if let base = utteranceRanges[ObjectIdentifier(utterance)] {
            currentRange = NSRange(location: base.location + characterRange.location, length: characterRange.length)
        } else {
            currentRange = characterRange
        }
    }
}
