//
//  OverlayMicrophone.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 03/02/24.
//

import SwiftUI

struct OverlayMicrophone: View {
    private let imageName: String
    private let backgroundColor: Color
    
    init(imageName: String, backgroundColor: Color) {
        self.imageName = imageName
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Circle()
            .fill(self.backgroundColor)
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: self.imageName)
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
            .transition(.scale.combined(with: .opacity)) // Add a transition for showing/hiding the overlay
            .zIndex(1) // Ensure the overlay is above the main content
    }
}

#Preview {
    OverlayMicrophone(imageName: "mic.fill", backgroundColor: CustomColor.customGrayMic)
}
