//
//  PaymentsVocalAssistantView.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI

public struct PaymentsVocalAssistantView: View {
    // View state
    @State private var conversationManager: ConversationManager!
    @State private var assistantAnswerText: String = ""
    @State private var isAssistantInitialized: Bool = false
    @State private var isRecordingInProgress: Bool = false
    
    // app state
    private let appContext: AppContext
    private let appDelegate: PaymentsVocalAssistantDelegate
    private let config: VocalAssistantCustomConfig

    
    public init(
        appContext: AppContext,
        appDelegate: PaymentsVocalAssistantDelegate,
        config: VocalAssistantCustomConfig = VocalAssistantCustomConfig()
    ) {
        self.appContext = appContext
        self.appDelegate = appDelegate
        self.config = config
    }
    
    public var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                VocalAssistantTitle(
                    self.config.title,
                    color: self.config.titleTextColor
                ).onAppear {
                    self.initializeVocalAssistant()
                }
                
                if !self.isAssistantInitialized {
                    VocalAssistantActivityIndicator()
                }
                else {
                    VocalAssistantAnswerBox(
                        assistantAnswer: self.assistantAnswerText,
                        textColor: self.config.assistantAnswerBoxTextColor,
                        boxBackground: self.config.assistantAnswerBoxBackground
                    )
                }
                
                Spacer()
                
                // button to record user's speech
                VocalAssistantRecButton(
                    disabled: !self.isAssistantInitialized,
                    imageName: self.config.recButtonImageName,
                    text: self.config.recButtonText,
                    textColor: self.config.recButtonForegroundColor,
                    fillColor: self.config.recButtonFillColor,
                    longPressStartAction: {
                        self.conversationManager.startListening()
                        
                        Task { @MainActor in
                            self.isRecordingInProgress = true
                        }
                    },
                    longPressEndAction: {
                        Task {
                            let assistantResponse = await self.conversationManager.processAndPlayResponse()
                            
                            Task { @MainActor in
                                self.isRecordingInProgress = false
                                self.assistantAnswerText = assistantResponse.completeAnswer
                                
                                // TODO: switch over the response and :
                                // - make some views appear if user has to choose among accounts or among contacts,
                                // - log/show error if there is an app error
                            }
                        }
                    }
                )
            }
            .padding(.bottom, 20)
            .background(self.config.backgroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // microphone icon in overlay
            if self.isRecordingInProgress {
                OverlayMicrophone(
                    imageName: self.config.recButtonImageName,
                    backgroundColor: CustomColor.customGrayMic
                )
            }
        }
        .animation(.easeInOut, value: self.isRecordingInProgress) // Animate the appearance/disappearance of the microphone overlay
    }
    
    private func initializeVocalAssistant() {
        Task { @MainActor in
            // instantiate the PaymentsVocalAssistant
            guard let vocalAssistant = await PaymentsVocalAssistant.instance(appContext: self.appContext) else {
                // initialization error occurred
                self.assistantAnswerText = self.config.initializationErrorMessage
                
                logError("PaymentsVocalAssistant is nil after getting singleton instance")
                self.isAssistantInitialized = true
                return
            }
            
            // create a new conversation with the specified opening message and error message
            self.conversationManager = vocalAssistant.newConversation(
                withMessage: self.config.startConversationQuestion,
                andDefaultErrorMessage: self.config.errorResponse,
                appDelegate: self.appDelegate
            )
            
            self.assistantAnswerText = self.conversationManager.startConversation()
            self.isAssistantInitialized = true
            logSuccess("vocal assistant initialized")
        }
    }
}

#Preview {
    PaymentsVocalAssistantView(
        appContext: AppContext.default,
        appDelegate: AppDelegateStub()
    )
}
