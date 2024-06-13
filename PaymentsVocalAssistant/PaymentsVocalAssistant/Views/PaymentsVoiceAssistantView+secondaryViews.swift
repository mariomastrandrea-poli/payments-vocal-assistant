//
//  PaymentsVoiceAssistantView+secondaryViews.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 13/06/24.
//

import Foundation
import SwiftUI

// - MARK: secondary views
extension PaymentsVocalAssistantView {
    @ViewBuilder
    internal var errorBox: some View {
        VocalAssistantAnswerBox(
            assistantAnswer: self.assistantInitErrorMessage,
            textColor: self.config.assistantAnswerBoxTextColor,
            boxBackground: self.config.assistantAnswerBoxBackground
        )
    }
    
    @ViewBuilder
    internal var recButton: some View {
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
                    self.isRequestLoading = true
                    let assistantResponse = await self.conversationManager.processAndPlayResponse()
                    self.launchTaskToReactTo(assistantResponse: assistantResponse)
                    self.isRequestLoading = false
                }
            }
        )
    }
    
    @ViewBuilder
    internal var answerBoxAndSelectionLists: some View {
        VocalAssistantAnswerBox(
            assistantAnswer: self.assistantAnswerText,
            textColor: self.config.assistantAnswerBoxTextColor,
            boxBackground: self.config.assistantAnswerBoxBackground
        )
        
        if self.chooseAmongContactsFlag && self.contactsList.isNotEmpty {
            contactsSelectionList
        }
        
        if self.isRequestLoading {
            VocalAssistantActivityIndicator()
        }
        
        if self.chooseAmongBankAccountsFlag && self.bankAccountsList.isNotEmpty {
            bankAccountsSelectionList
        }
        
        if self.appErrorFlag && self.appError.isNotEmpty {
            appErrorText
        }
    }
    
    @ViewBuilder
    private var contactsSelectionList: some View {
        VocalAssistantSelectionList(
            elements: self.contactsList,
            color: self.config.assistantAnswerBoxBackground,
            onTap: { contact in
                Task {
                    self.isRequestLoading = true
                    let assistantResponse = await self.conversationManager.userSelects(contact: contact)
                    self.launchTaskToReactTo(assistantResponse: assistantResponse)
                    self.isRequestLoading = false
                }
            }
        )
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var bankAccountsSelectionList: some View {
        VocalAssistantSelectionList(
            elements: self.bankAccountsList,
            color: self.config.assistantAnswerBoxBackground,
            onTap: { bankAccount in
                Task {
                    self.isRequestLoading = true
                    let assistantResponse = await self.conversationManager.userSelects(
                        bankAccount: bankAccount
                    )
                    self.launchTaskToReactTo(assistantResponse: assistantResponse)
                    self.isRequestLoading = false
                }
            }
        )
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var appErrorText: some View {
        VStack {
            Text(self.appError)
        }
        .foregroundColor(self.config.assistantAnswerBoxTextColor)
        .padding(.all, 18)
        .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
        .background(Color.red.opacity(0.7))
        .cornerRadius(10)
    }
}
