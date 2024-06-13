//
//  TypewriterText.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI
import Combine

class TextWrapper: ObservableObject {
    @Published var text: String = ""
}

public struct TypewriterText<NextContent:View> : View {
    var speed: TimeInterval  // Speed of the typewriter effect

    @ObservedObject private var textWrapper = TextWrapper()
    @State private var displayedText: String = ""
    @State private var charIndex: Int = 0
    
    @State private var timerSubscription: AnyCancellable?
    @State private var typingEnded: Bool = false
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var next: NextContent
    
    
    public init(_ text: String, speed: TimeInterval = 0.02, @ViewBuilder next: () -> NextContent) {
        self.speed = speed
        self.next = next()
        self.textWrapper.text = text
        self.typingEnded = false
    }
        
    public var body: some View {
        Text(self.displayedText)
            .onReceive(self.textWrapper.$text) { newText in
                self.displayedText = ""
                self.charIndex = 0
                self.typingEnded = false
                
                self.feedbackGenerator.prepare()
                let timer = Timer.publish(every: self.speed, on: .main, in: .common).autoconnect()
                
                // cancel any previous timer
                self.timerSubscription?.cancel()
                
                // set the new timer
                self.timerSubscription = timer.sink { _ in
                    if self.charIndex < newText.count {
                        let index = newText.index(newText.startIndex, offsetBy: self.charIndex)
                        let newChar = newText[index]
                        self.displayedText += String(newChar)
                        self.charIndex += 1
                    
                        if newChar.isWhitespace {
                            // for each new word
                            self.feedbackGenerator.impactOccurred()
                        }
                    }
                    else {
                        self.feedbackGenerator.impactOccurred()
                        // unsubscribe
                        self.timerSubscription?.cancel()
                        
                        self.typingEnded = true
                    }
                }
            }
            .onDisappear {
                self.timerSubscription?.cancel()
            }
        
        if self.typingEnded {
            self.next
        }
    }
}

#Preview {
    TypewriterText(
        "This is an example of text inside the Vocal assistant answer box"
    ) {}
}
