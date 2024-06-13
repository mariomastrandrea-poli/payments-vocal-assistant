//
//  TestAppMainView.swift
//  PaymentsVocalAssistant_testApp
//
//  Created by Mario Mastrandrea on 05/02/24.
//

import SwiftUI
import Contacts

struct TestAppMainView: View {
    private static let title = "Hi there! 🚀"
    private static let buttonLabel = "Start"
        
    private static let formUrl = "https://forms.gle/EVn8UkvKaEVwHADo6"
    private static let formLabel = "Go to form"
    private static let descriptionFontSize = 18.5
    
    let contactStore: CNContactStore
    
    init() {
        self.contactStore = CNContactStore()
        
        UIPageControl.appearance().currentPageIndicatorTintColor = .label
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.2)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 5) {
                Text(TestAppMainView.title)
                    .bold()
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                                
                VStack {
                    swipeableTabViews
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 35)
                .cornerRadius(30)
            }
            .padding(.horizontal, 35)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var swipeableTabViews: some View {
        TabView {
            TestAppSimpleTextView(
                text: TestAppMainView.greetingsDescription,
                size: TestAppMainView.descriptionFontSize
            )
            TestAppSimpleTextView(
                text: TestAppMainView.contextDescription,
                size: TestAppMainView.descriptionFontSize
            )
            TestAppSimpleTextView(
                text: TestAppMainView.assistantDescription,
                size: TestAppMainView.descriptionFontSize
            )
            TestAppSimpleTextView(
                text: TestAppMainView.assistantDetailsDescription,
                size: TestAppMainView.descriptionFontSize
            )
            TestAppFormView(
                text: TestAppMainView.formDescription,
                size: TestAppMainView.descriptionFontSize,
                formUrl: TestAppMainView.formUrl,
                formLabel: TestAppMainView.formLabel
            )
            TestAppVocalAssistantWrapperView(
                text: TestAppMainView.vocalAssistantWrapperDescription,
                size: TestAppMainView.descriptionFontSize,
                buttonLabel: TestAppMainView.buttonLabel,
                labelSize: TestAppMainView.descriptionFontSize,
                contactStore: self.contactStore
            )
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic)) // Makes the TabView swipeable
    }
}



#Preview {
    TestAppMainView()
}

