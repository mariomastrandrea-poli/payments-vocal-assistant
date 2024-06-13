//
//  PaymentsVocalAssistantView.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI

public struct PaymentsVocalAssistantView: View {
    // View state
    @State internal var conversationManager: ConversationManager!
    @State internal var assistantAnswerText: String = ""
    
    @State internal var isAssistantInitialized: Bool = false
    @State internal var isRecordingInProgress: Bool = false
    @State internal var initErrorOccurred: Bool = false
    @State internal var assistantInitErrorMessage: String = ""
    @State internal var isRequestLoading: Bool = false
    
    @State internal var chooseAmongBankAccountsFlag: Bool = false
    @State internal var bankAccountsList: [VocalAssistantBankAccount] = []
    @State internal var chooseAmongContactsFlag: Bool = false
    @State internal var contactsList: [VocalAssistantContact] = []
    
    @State internal var appErrorFlag: Bool = false
    @State internal var appError: String = ""
    
    // app state
    private let appContext: AppContext?
    private let appDelegate: PaymentsVocalAssistantDelegate?
    internal let initErrorMessage: String
    internal let config: VocalAssistantCustomConfig
    
    
    public init(
        appContext: AppContext?,
        appDelegate: PaymentsVocalAssistantDelegate?,
        initErrorMessage: String?,
        config: VocalAssistantCustomConfig = VocalAssistantCustomConfig()
    ) {
        self.appContext = appContext
        self.appDelegate = appDelegate
        self.initErrorMessage = initErrorMessage ?? "An unexpected error occurred"
        self.config = config
        
        self.assistantAnswerText = ""
        self.isAssistantInitialized = false
        self.isRecordingInProgress = false
        self.initErrorOccurred = false
        self.assistantInitErrorMessage = ""
        self.isRequestLoading = false
        self.chooseAmongBankAccountsFlag = false
        self.bankAccountsList = []
        self.chooseAmongContactsFlag = false
        self.contactsList = []
        self.appErrorFlag = false
        self.appError = ""
    }
    
    public var body: some View {
        ZStack {
            vocalAssistantScreenView
            
            // microphone icon in overlay
            if self.isRecordingInProgress {
                overlayMicrophoneIcon
            }
        }  // Animate the appearance/disappearance of the microphone
        .animation(.easeInOut, value: self.isRecordingInProgress)
        .onDisappear {
            self.conversationManager?.stopSpeaking()
        }
    }
}


// - MARK: init and business logic
extension PaymentsVocalAssistantView {
    internal func initializeVocalAssistant() async {
        // check that all the Assistant dependencies are correctly injected
        guard let appContext = self.appContext, let appDelegate = self.appDelegate else {
            self.assistantInitErrorMessage = self.initErrorMessage
            self.initErrorOccurred = true
            return
        }
        
        // instantiate the PaymentsVocalAssistant
        guard let vocalAssistant = await PaymentsVocalAssistant.instance(appContext: appContext) else {
            // initialization error occurred
            self.assistantInitErrorMessage = self.config.assistantInitializationErrorMessage
            
            logError("PaymentsVocalAssistant is nil after getting singleton instance")
            self.initErrorOccurred = true
            return
        }
        
        // create a new conversation with the specified opening message and error message
        self.conversationManager = vocalAssistant.newConversation(
            withMessage: self.config.startConversationQuestion,
            andDefaultErrorMessage: self.config.errorResponse,
            maxNumOfLastTransactions: self.config.maxNumOfLastTransactions,
            appDelegate: appDelegate
        )
        
        self.assistantAnswerText = self.conversationManager.startConversation()
        self.isAssistantInitialized = true
        logSuccess("vocal assistant initialized")
    }
    
    internal func launchTaskToReactTo(assistantResponse: VocalAssistantResponse) {
        Task { @MainActor in
            self.isRecordingInProgress = false
            self.assistantAnswerText = assistantResponse.completeAnswer
            
            // reset state
            self.appError = ""
            self.appErrorFlag = false
            self.contactsList = []
            self.chooseAmongContactsFlag = false
            self.bankAccountsList = []
            self.chooseAmongBankAccountsFlag = false
            
            // show/hide list or error
            switch assistantResponse {
            case .appError(let errorMessage, _, _):
                self.appError = errorMessage
                self.appErrorFlag = true
            case .justAnswer(_, _):
                break
            case .askToChooseContact(let contacts, _, _):
                self.contactsList = contacts
                self.chooseAmongContactsFlag = true
            case .askToChooseBankAccount(let bankAccounts, _, _):
                self.bankAccountsList = bankAccounts
                self.chooseAmongBankAccountsFlag = true
            case .performInAppOperation(_, _, _, _, _):
                break
            }
        }
    }
}

#Preview {
    PaymentsVocalAssistantView(
        appContext: AppContext.default,
        appDelegate: AppDelegateStub(),
        initErrorMessage: nil
    )
}
