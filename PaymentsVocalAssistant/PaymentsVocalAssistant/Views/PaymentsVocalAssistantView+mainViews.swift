//
//  PaymentsVocalAssistantView+mainViews.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 13/06/24.
//

import Foundation
import SwiftUI

// - MARK: main views
extension PaymentsVocalAssistantView {
    @ViewBuilder
    internal var vocalAssistantScreenView: some View {
        VStack(alignment: .leading) {
            VocalAssistantTitle(
                self.config.title,
                color: self.config.titleTextColor
            ).onAppear {
                Task {
                    await self.initializeVocalAssistant()
                }
            }
            
            if self.isAssistantInitialized {
                answerBoxAndSelectionLists
            }
            else if self.initErrorOccurred {
                errorBox
            }
            else {
                VocalAssistantActivityIndicator()
            }
            
            Spacer()
            
            // button to record user's speech
            recButton
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
        .background(self.config.backgroundColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    internal var overlayMicrophoneIcon: some View {
        OverlayMicrophone(
            imageName: self.config.recButtonImageName,
            backgroundColor: CustomColor.customGrayMic
        )
    }
}
