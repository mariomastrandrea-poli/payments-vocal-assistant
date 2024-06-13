//
//  SpeechSynthesizer.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import Foundation
import AVFoundation

class SpeechSynthesizer {
    private let language: String
    private let speechSynthesizer: AVSpeechSynthesizer
    private let speechVoice: AVSpeechSynthesisVoice?
    
    // utterance properties
    private let speechUtteranceRateMultiplier: Float
    
    init() {
        let tempLanguage = SpeechConfig.defaultLocaleIdWithDash
        
        self.language = tempLanguage
        self.speechUtteranceRateMultiplier = SpeechConfig.speechUtteranceRateMultiplier
        self.speechSynthesizer = AVSpeechSynthesizer()
        
        let availableVoices = AVSpeechSynthesisVoice
                                    .speechVoices()
                                    .filter { voice in voice.language == tempLanguage }
        
        self.speechVoice = availableVoices.first { voice in
            if #available(iOS 16.0, *) {
                return voice.quality == .premium
            }
            else {
               return false
            }
        } 
        ?? availableVoices.first { voice in
            voice.quality == .enhanced
        } 
        ?? AVSpeechSynthesisVoice(language: self.language)
    }
    
    func stopSpeaking() {
        // first stop any previous speech
        self.speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    func speak(text: String) {
        // first stop any previous speech
        self.stopSpeaking()
        
        do {
            // setup audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch let error {
            logError("An error occurred during audio session setup for SpeechSynthesizer. \(error.localizedDescription)")
            return
        }
        
        // * create and configure the utterance's properties *
        let utterance = AVSpeechUtterance(string: text)
        
        // force an English voice here
        utterance.voice = self.speechVoice
        
        // turn up the voice speed
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * self.speechUtteranceRateMultiplier
        
        // max voice volume
        utterance.volume = Float(1.0)
        
        logInfo("Utterance info ->  Rate: \(utterance.rate)  -  Volume: \(utterance.volume)  -  Voice: \(utterance.voice?.name ?? "default")")
        logInfo("Utterance voicee ->  Name: \(utterance.voice?.name ?? "none")  -  Identifier: \(utterance.voice?.identifier ?? "none")  -  Language: \(utterance.voice?.language ?? "none")  -  Quality: \(utterance.voice?.quality != nil ? String(describing: utterance.voice!.quality) : "none")")
        
        // Start speaking
        self.speechSynthesizer.speak(utterance)
    }
}
