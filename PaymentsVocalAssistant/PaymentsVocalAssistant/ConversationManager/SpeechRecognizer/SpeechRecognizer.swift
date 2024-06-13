//
//  SpeechRecognizer.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 16/01/24.
//

import Foundation
import Speech
import AVFoundation
import Contacts

enum SpeechRecognizerError: Error {
    case nilRecognizer
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable
    case notSupportedOnDeviceRecognition
    case customLMnotCreated
    case customLMnotExported(localizedDescription: String)
    case customLMnotPrepared(localizedDescription: String)
    
    var message: String {
        switch self {
        case .nilRecognizer: return "Can't initialize speech recognizer"
        case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
        case .notPermittedToRecord: return "Not permitted to record audio"
        case .recognizerIsUnavailable: return "Recognizer is unavailable"
        case .notSupportedOnDeviceRecognition: return "On-device recognition not supported by the Recognizer"
        case .customLMnotCreated: return "Failed Custom Language model creation from templates and user app context"
        case .customLMnotExported(let localizedDescription): return "Failed Custom LM export.\n\(localizedDescription)"
        case .customLMnotPrepared(let localizedDescription): return "An error occurred preparing Custom data Model: \(localizedDescription)"
        }
    }
}

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
class SpeechRecognizer {
    var bestTranscript: String = ""
    var transcripts: [String] = []
    var errorOccurred: Bool = false
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    private var customLMconfig: AnyObject? = nil
    
    /**
     Initializes a new speech recognizer. If this is the first time you've used the class, it
     requests access to the speech recognizer and the microphone.
     */
    init?(testMode: Bool = false) async {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: SpeechConfig.defaultLocaleId))
        
        if testMode { return }  // skip checks and user's permissions requests in test mode
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            transcribe(SpeechRecognizerError.nilRecognizer)
            return nil
        }
        
        // check if on-device speech recognition is supported
        // (but from iOS 13, on Device Speech Recognition should be supported by any device)
        if !recognizer.supportsOnDeviceRecognition {
            logError("Error: on-device speech recognition NOT supported")
        }
        else {
            logInfo("On-device speech recognition supported")
        }
        
        // check user's permissions for recording and for speech recognizer (STT)
                
        do {
            guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                throw SpeechRecognizerError.notAuthorizedToRecognize
            }
            guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                throw SpeechRecognizerError.notPermittedToRecord
            }
        }
        catch {
            transcribe(error)
            return nil
        }
    }
    
    func createCustomLM(names: [String], surnames: [String], banks: [String]) async {
        // Custom Language Model for Speech Recognition is only available from iOS 17
        if #available(iOS 17, *) {
            
            let customLMcreationResult = logElapsedTimeInMs(
                of: "Custom Language model successfully created from templates and user's app context",
                type: .success
            ) {
                // create the Custom Language Model builder
                let lmBuilder = CustomLMBuilder(locale: Locale(identifier: "en_US"))
                
                // import data from the csv
                let dataAdded = lmBuilder.build(
                    withNames: names,
                    surnames: surnames,
                    banks: banks,
                    andTemplatesFromCsv: SpeechConfig.CustomLM.templatesFileName
                )
                
                return dataAdded ? .success(lmBuilder) : .failure(SpeechRecognizerError.customLMnotCreated)
            }
            
            guard customLMcreationResult.isSuccess else {
                logError(customLMcreationResult.failure!.message)
                return
            }
            
            let lmBuilder = customLMcreationResult.success!
            
            let customLMexportResult = await asyncLogElapsedTimeInMs(
                of: "Custom Language model successfully export into .bin",
                type: .success
            ) {
                // export Custom LM data into a file
                await lmBuilder.export(fileName: SpeechConfig.CustomLM.modelFileName)
            }
            
            guard customLMexportResult.isSuccess else {
                logError(customLMexportResult.failure!.message)
                return
            }
            
            let customModelUrl = customLMexportResult.success!
            
            // * now import again the Custom LM from the exported file and
            //   prepare the custom language model
            
            let customDataId = SpeechConfig.CustomLM.identifier
            let customLMConfig = SFSpeechLanguageModel.Configuration(
                languageModel: customModelUrl
            )
            
            let customLMpreparationResult = await asyncLogElapsedTimeInMs(
                of: "Custom Language Model successfully prepared",
                type: .success
            ) {
                let result: Result<Void, SpeechRecognizerError>
                
                do {
                    // Prepare the Custom Language Model for the Speech Recognizer
                    try await SFSpeechLanguageModel.prepareCustomLanguageModel(
                        for: customModelUrl,
                        clientIdentifier: customDataId,
                        configuration: customLMConfig
                    )
                    
                    // save custom LM configuration
                    self.customLMconfig = customLMConfig
                    
                    result = .success(())
                }
                catch let error {
                    result = .failure(
                        SpeechRecognizerError.customLMnotPrepared(localizedDescription: error.localizedDescription)
                    )
                }
                
                return result
            }
            
            guard customLMpreparationResult.isSuccess else {
                logError(customLMpreparationResult.failure!.message)
                return
            }
        }
        else {
            logInfo("** Custom Language model not available on this device **")
        }
    }
    
    func startTranscribing() {
        self.bestTranscript = ""
        self.transcripts = []
        self.errorOccurred = false
        
        self.transcribe()
    }
    
    func stopTranscribing() {
        self.stop()
    }
    
    func resetTranscript() {
        self.reset()
    }
    

    /**
     Begin transcribing audio.
     
     Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
     The resulting transcription is continuously written to the `transcript` property.
     */
    private func transcribe() {
        guard let recognizer else {
            self.transcribe(SpeechRecognizerError.recognizerIsUnavailable)
            return
        }
        
        if self.task != nil {
            self.task?.cancel()
            self.task = nil
        }
        
        do {
            // prepare to record and process the speech
            let (audioEngine, request) = try self.prepareEngine(for: recognizer)
            self.audioEngine = audioEngine
            self.request = request
            
            self.task = recognizer.recognitionTask(
                with: request,
                resultHandler: { [weak self] result, error in
                    self?.recognitionHandler(
                        audioEngine: audioEngine,
                        result: result,
                        error: error
                    )
                }
            )
        }
        catch {
            self.reset()
            self.transcribe(error)
        }
    }
    
    /// Reset the speech recognizer.
    private func stop() {
        task?.finish()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    /// Reset the speech recognizer.
    private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private func prepareEngine(for recognizer: SFSpeechRecognizer) throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        if recognizer.supportsOnDeviceRecognition {
            // *** force on-device recognition ***
            request.requiresOnDeviceRecognition = true
                
            if #available(iOS 17, *) {
                if let customLMconfig = self.customLMconfig as? SFSpeechLanguageModel.Configuration {
                    request.customizedLanguageModel = customLMconfig
                    logInfo("Using customized language model for the request")
                }
                else {
                    logError("An error occurred retrieving the custom LM configuration")
                }
            }
        }
        else {
            // just proceed with *online* Speech Recognition
            logError("*** On device Recognition is not available! ***")
        }
        
        // setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    private func recognitionHandler(
        audioEngine: AVAudioEngine,
        result: SFSpeechRecognitionResult?,
        error: Error?
    ) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            self.bestTranscript = result.bestTranscription.formattedString
            self.transcripts = result.transcriptions.map { $0.formattedString }
        }
    }
    
    private func transcribe(_ error: Error) {
        var errorMessage = ""
        if let error = error as? SpeechRecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        
        errorMessage = "<< \(errorMessage) >>"
        self.errorOccurred = true
        logError(errorMessage)
        
        Task { @MainActor [errorMessage] in
            self.bestTranscript = errorMessage
            self.transcripts = [errorMessage]
        }
    }
}


extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}


extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}

