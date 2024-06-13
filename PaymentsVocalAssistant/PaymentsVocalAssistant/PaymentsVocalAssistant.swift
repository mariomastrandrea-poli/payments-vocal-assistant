//
//  PaymentsVocalAssistant.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 23/01/24.
//

import Foundation

public enum AssistantModelType {
    case bert
}

public class PaymentsVocalAssistant {
    private static let testMode = false
    
    // singleton instance
    private static var _instance: PaymentsVocalAssistant? = nil
    private static let type: AssistantModelType = .bert
    
    // app context
    private var appContext: AppContext
    
    private let intentAndEntitiesExtractor: any IntentAndEntitiesExtractor
    private let speechRecognizer: SpeechRecognizer
    private let speechSynthesizer: SpeechSynthesizer
    
    
    /**
     Initialize the Vocal Assistant specifying the requested type
     
     Call this method just once, at app initialization time
     */
    private init?(
        appContext: AppContext
    ) async {
        // initialize a Intent and Entities Extractor
        switch PaymentsVocalAssistant.type {
            case .bert:
                guard let intentAndEntitiesExtractor =
                        PaymentsVocalAssistant.createBertIntentAndEntitiesExtractor() else { return nil }
                self.intentAndEntitiesExtractor = intentAndEntitiesExtractor
            }
        
        // initialize speech recognizer, eventually with a Custom Language model (iOS >=17)
        guard let speechRecognizer = await SpeechRecognizer(
            testMode: PaymentsVocalAssistant.testMode
        ) else { return nil }
        
        self.speechRecognizer = speechRecognizer
        
        await self.speechRecognizer.createCustomLM(
            names: appContext.userContacts.compactMap { $0.firstName.isEmpty ? nil : $0.firstName },
            surnames: appContext.userContacts.compactMap { $0.lastName.isEmpty ? nil : $0.lastName },
            banks: appContext.userBankAccounts.map { $0.name }
        )
         
        // initialize speech synthesizer
        self.speechSynthesizer = SpeechSynthesizer()
        
        // save app context
        self.appContext = appContext
    }
    
    /** Return the singleton instance of the Vocal Assistant.
        - parameter appContext: object enclosing the app context's entities which might be referred by the user in the conversation
     
        If this is the first time the method is called, it instantiates and initializes the
        Vocal Assistant with its subcomponents, so this call might take a long time */
    public static func instance(
        appContext: AppContext = AppContext.default
    ) async -> PaymentsVocalAssistant? {
        if _instance == nil {
            _instance = await PaymentsVocalAssistant(
                appContext: appContext
            )
        }
        else {
            // just update the app context
            _instance?.appContext = appContext
        }
        
        return _instance
    }
    
    /**
     Create a new instance of BERT extractor injecting all its dependencies
     */
    private static func createBertIntentAndEntitiesExtractor() -> BertIntentAndEntitiesExtractor? {
        // create BERT Preprocessor
        guard let bertTokenizer = BertTokenizer() else { return nil }
        
        let bertPreprocessor = BertPreprocessor(tokenizer: bertTokenizer)
        logSuccess("* created BERT preprocessor * ")
        
        // create BERT model
        guard let bertModel = BertTFLiteIntentAndEntitiesClassifier(
            tfLiteModelFile: BertConfig.modelFile
        )
        else { return nil }
        logSuccess("* created TF Lite BERT classifier *")
           
        // create BERT labeler
        let bertLabeler = BertIntentEntityLabeler()
        
        // create BERT text classifier
        let bertTextClassifier = BertTextClassifier(
            preprocessor: bertPreprocessor,
            model: bertModel,
            labeler: bertLabeler
        )
        
        // create the BERT intent and entities extractor
        let bertExtractor = BertIntentAndEntitiesExtractor(classifier: bertTextClassifier)
        logSuccess("* created BERT intent and entities extractor * ")
        
        return bertExtractor
    }
    
    /**
     Create a new conversation and get the corresponding dialogue manager
     - parameter startConversationMessage: the default message used by the vocal assistant to start the conversation
     - parameter defaultErrorMessage: the default message used by the vocal assistant when an unexpected error occurs
     - parameter appDelegate: the object responsible of performing the in-app operations requested by the user
     
     Call this method each time the user is starting a new conversation
     */
    public func newConversation(
        withMessage startConversationMessage: String,
        andDefaultErrorMessage defaultErrorMessage: String,
        maxNumOfLastTransactions: Int,
        appDelegate: PaymentsVocalAssistantDelegate
    ) -> ConversationManager {
        // create a new DST dependency to manage the new conversation
        let dst = VocalAssistantDst(
            intentAndEntitiesExtractor: self.intentAndEntitiesExtractor,
            appContext: self.appContext,
            defaultErrorMessage: defaultErrorMessage,
            startConversationMessage: startConversationMessage
        )
        
        return ConversationManager(
            speechRecognizer: self.speechRecognizer,
            dst: dst,
            speechSyntesizer: self.speechSynthesizer,
            appDelegate: appDelegate,
            defaultErrorMessage: defaultErrorMessage,
            maxNumOfLastTransactions: maxNumOfLastTransactions
        )
    }
}
