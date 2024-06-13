//
//  VocalAssistantSelectionList.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 04/02/24.
//

import SwiftUI

struct VocalAssistantSelectionList<T>: View 
 where T: CustomStringConvertible, T: Identifiable {
    private var elements: [T] = []
    private var elementCallback: (T) -> Void = { _ in () }
    private var color: Color
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    
    init(elements: [T], color: Color, onTap: @escaping (T) -> Void) {
        self.elements = elements
        self.elementCallback = onTap
        self.color = color
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0, content: {
                ForEach(self.elements) { element in
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                        elementCallback(element)
                    }) {
                        HStack(alignment: .center, content: {
                            Text(element.description)
                            Spacer()
                        })
                        .padding(.horizontal, 30)
                        .padding(.vertical, 17)
                        .border(Color.black.opacity(0.15), width: 0.2)
                    }                    
                }
            })
            .background(self.color)
            .cornerRadius(25)
        }
    }
}

#Preview {
    VocalAssistantSelectionList(
        elements: [
            VocalAssistantContact(id: "1", firstName: "Antonio", lastName: "Rossi"),
            VocalAssistantContact(id: "2", firstName: "Giuseppe", lastName: "Verdi"),
            VocalAssistantContact(id: "3", firstName: "Antonio", lastName: "Rossi"),
            VocalAssistantContact(id: "4", firstName: "Giuseppe", lastName: "Verdi"),
            VocalAssistantContact(id: "5", firstName: "Antonio", lastName: "Rossi"),
            VocalAssistantContact(id: "6", firstName: "Giuseppe", lastName: "Verdi")
        ],
        color: Color.gray.opacity(0.4),
        onTap: { _ in () }
    )
}
