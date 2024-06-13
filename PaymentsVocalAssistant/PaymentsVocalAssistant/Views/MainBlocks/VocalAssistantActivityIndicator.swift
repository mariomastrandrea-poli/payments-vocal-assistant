//
//  AssistantActivityIndicator.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 29/01/24.
//

import SwiftUI
import UIKit

public struct VocalAssistantActivityIndicator: View {
    private let style: UIActivityIndicatorView.Style
    
    public var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            SwiftUIActivityIndicator(style: self.style)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
    
    public init(style: UIActivityIndicatorView.Style = .large) {
        self.style = style
    }
}

/** Basic Activity Indicator wrapper of the UIKit ActivityIndicatorView, to make it compatible with iOS 13 */
public struct SwiftUIActivityIndicator: UIViewRepresentable {
    public typealias UIViewType = UIActivityIndicatorView
    
    var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    public init(isAnimating: Bool = true, style: UIActivityIndicatorView.Style = .large) {
        self.isAnimating = isAnimating
        self.style = style
    }

    public func makeUIView(context: UIViewRepresentableContext<SwiftUIActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    public func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<SwiftUIActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

#Preview {
    VocalAssistantActivityIndicator()
}
