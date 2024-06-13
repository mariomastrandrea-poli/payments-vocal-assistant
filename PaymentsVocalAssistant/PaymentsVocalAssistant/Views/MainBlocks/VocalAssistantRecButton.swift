//
//  VocalAssistantRecButton.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI

struct VocalAssistantRecButton: View {
    @State private var isRecPressed = false

    private let disabled: Bool
    private let imageName: String
    private let text: String
    private let textColor: Color
    private let fillColor: Color
    private let longPressStartAction: () -> Void
    private let longPressEndAction: () -> Void
    
    private let hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private var longPressMinimumDurationInSec: Double {
        return Double(SpeechConfig.defaultStartDelayMs) / 1000.0
    }
    
    init(disabled: Bool, imageName: String, text: String, textColor: Color, fillColor: Color, longPressStartAction: @escaping () -> Void, longPressEndAction: @escaping () -> Void) 
    {
        self.disabled = disabled
        self.imageName = imageName
        self.text = text
        self.textColor = textColor
        self.fillColor = fillColor
        self.longPressStartAction = longPressStartAction
        self.longPressEndAction = longPressEndAction
    }
    
    var body: some View {
        // button to record user's speech
        HStack {
            Image(systemName: self.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)
                .foregroundColor(self.textColor.opacity(self.disabled ? 0.5 : 1.0))
            Text(self.text)
                .foregroundColor(self.textColor.opacity(self.disabled ? 0.5 : 1.0))
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            self.fillColor.opacity(
                self.disabled ? 0.4 : self.isRecPressed ? 0.7 : 1.0
            )
        )
        .cornerRadius(10)
        .gesture(
            LongPressGesture(minimumDuration: longPressMinimumDurationInSec)
                .onEnded { _ in
                    // this triggers when the *long* press starts (after min duration)
                    if !self.disabled {
                        longPressStartAction()
                    }
                }
                .sequenced(
                    before: DragGesture(minimumDistance: 0).onEnded { _ in
                        // this triggers once the long press ended
                        if !self.disabled {
                            Task {
                                do {
                                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                                      
                                    longPressEndAction()
                                } catch {
                                    // Handle cancellation or other errors
                                    logError("Task was unexpectedly cancelled or encountered an error")
                                }
                            }
                        }
                    }
                )
        )
        .simultaneousGesture(
            // monitor button press state and trigger haptic feedback
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !self.disabled {
                        if !self.isRecPressed {
                            hapticFeedbackGenerator.impactOccurred()
                        }
                        
                        self.isRecPressed = true
                    }
                }
                .onEnded { _ in
                    if !self.disabled {
                        self.isRecPressed = false
                        hapticFeedbackGenerator.impactOccurred()
                    }
                }
        )
        
    }
}

#Preview {
    VocalAssistantRecButton(
        disabled: true,
        imageName: "mic.fill",
        text: "Hold to speak",
        textColor: Color.white,
        fillColor: Color.blue,
        longPressStartAction: {},
        longPressEndAction: {}
    )
}
