//
//  AssistantActivityIndicator.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI
import UIKit

public struct VocalAssistantActivityIndicator: View {
    public var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            SwiftUIActivityIndicator()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
    
    public init() {}
}

/** Basic Activity Indicator wrapper of the UIKit ActivityIndicatorView, to make it compatible with iOS 13 */
struct SwiftUIActivityIndicator: UIViewRepresentable {
    typealias UIViewType = UIActivityIndicatorView
    
    var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    init(isAnimating: Bool = true, style: UIActivityIndicatorView.Style = .large) {
        self.isAnimating = isAnimating
        self.style = style
    }

    func makeUIView(context: UIViewRepresentableContext<SwiftUIActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<SwiftUIActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

#Preview {
    VocalAssistantActivityIndicator()
}