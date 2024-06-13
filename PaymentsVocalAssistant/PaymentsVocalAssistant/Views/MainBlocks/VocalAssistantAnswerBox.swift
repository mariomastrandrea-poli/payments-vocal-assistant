//
//  AssistantAnswerBox.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI

struct VocalAssistantAnswerBox: View {
    private let assistantAnswer: String
    private let textColor: Color
    private let boxBackground: Color
     
    
    init(assistantAnswer: String, textColor: Color, boxBackground: Color) {
        self.assistantAnswer = assistantAnswer
        self.textColor = textColor
        self.boxBackground = boxBackground
    }
    
    var body: some View {
        VStack {
            TypewriterText(self.assistantAnswer) {}
        }
        .foregroundColor(self.textColor)
        .padding(.all, 18)
        .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
        .background(self.boxBackground)
        .cornerRadius(10)
    }
}

#Preview {
    VocalAssistantAnswerBox(
        assistantAnswer: "Hi! How can I help you?",
        textColor: Color.primary,
        boxBackground: CustomColor.customGray
    )
}
