//
//  VocalAssistantTitle.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI

struct VocalAssistantTitle: View {
    private let title: String
    private let color: Color
    
    init(_ title: String, color: Color) {
        self.title = title
        self.color = color
    }
    
    var body: some View {
        Text(title)
            .foregroundColor(color)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 18)
            .font(Font.title)
    }
}

#Preview {
    VocalAssistantTitle("Payments Vocal Assistant", color: Color.primary)
}
