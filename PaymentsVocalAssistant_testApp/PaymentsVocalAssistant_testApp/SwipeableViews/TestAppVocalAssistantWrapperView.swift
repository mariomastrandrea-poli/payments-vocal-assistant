//
//  TestAppVocalAssistantWrapper.swift
//  PaymentsVocalAssistant_testApp
//
//  Created by Mario Mastrandrea on 06/02/24.
//

import SwiftUI
import PaymentsVocalAssistant
import Contacts

struct TestAppVocalAssistantWrapperView: View {
    private let text: String
    private let size: Double
    private let buttonLabel: String
    private let labelSize: Double
    private let contactStore: CNContactStore
    
    @State private var appDelegateStub: PaymentsVocalAssistantDelegate? = nil
    @State private var appContext: AppContext? = nil
    @State private var initErrorMessage: String? = nil
    @State private var appInitializationCompleted: Bool = false
    @State private var appIsInitializing: Bool = false
    
    
    init(text: String, size: Double, buttonLabel: String, labelSize: Double, contactStore: CNContactStore) {
        self.text = text
        self.size = size
        self.buttonLabel = buttonLabel
        self.labelSize = labelSize
        self.contactStore = contactStore
    }
    
    var body: some View {
        VStack {
            Text(self.text)
                .font(.system(size: self.size))
            
            Spacer()
            
            buttonToStartVocalAssistant
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var buttonToStartVocalAssistant: some View {
        Button(
            action: {
                self.appIsInitializing = true
                
                self.initContactsAndBankAccounts()
            },
            label: {
                if self.appIsInitializing {
                    VocalAssistantActivityIndicator()
                }
                else {
                    Text(self.buttonLabel)
                        .bold()
                        .font(.system(size: self.labelSize))
                }
            }
        )
        .frame(width: 110, height: 110)
        .padding(20)
        .background(Color.blue)
        .cornerRadius(2000)
        .padding(.vertical, 10)
        .foregroundColor(Color.white)
        .padding(60)
        
        NavigationLink(
            destination: PaymentsVocalAssistantView(
                appContext: self.appContext,
                appDelegate: self.appDelegateStub,
                initErrorMessage: self.initErrorMessage
            ),
            isActive: self.$appInitializationCompleted
        ) {
            EmptyView()
        }
        .hidden()
    }
    
    private func initContactsAndBankAccounts() {
        Task {
            // fetch contacts
            let contacts = await self.fetchContacts()
            
            guard let contacts = contacts else {
                Task { @MainActor in
                    // an error occurred retrieving contacts
                    self.initErrorMessage = "Sorry, an error occurred in accessing your contacts, we apologize for the inconvenience. Please exit and try again later.\nIf the error persists, check in your System Preferences that this app has the 'Contacts' permission."
                    
                    self.appIsInitializing = false
                    
                    // Trigger the navigation
                    self.appInitializationCompleted = true
                }
                return
            }
            
            Task { @MainActor in
                let appDelegate = AppDelegateStub(
                    contacts: contacts,
                    transactions: []
                )
                self.appDelegateStub = appDelegate
                self.appContext = AppContext(
                    userContacts: contacts,
                    userBankAccounts: Array(appDelegate.bankAccounts.keys)
                )
                
                self.appIsInitializing = false
                
                // Trigger the navigation
                self.appInitializationCompleted = true
            }
        }
    }
}

// - MARK: ContactStore
extension TestAppVocalAssistantWrapperView {
    private func fetchContacts() async -> [VocalAssistantContact]? {
        _ = await self.contactStore.askPermissionToAccessContacts()
        
        if !self.isContactsPermissionGranted() { return nil }

        let keysToFetch = [CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [VocalAssistantContact] = []
        
        do {
            try self.contactStore.enumerateContacts(with: fetchRequest) { (contact, stop) in
                if !contact.phoneNumbers.isEmpty {
                    let number = contact.phoneNumbers[0].value.stringValue
                    let name = contact.givenName
                    let surname = contact.familyName
                    
                    if !number.isEmpty && !(name+surname).isEmpty {
                        let contact = VocalAssistantContact(id: number, firstName: name, lastName: surname)
                        contacts.append(contact)
                    }
                }
                
            }
        }
        catch let error {
            print("Failed to fetch contacts, error: \(error.localizedDescription)")
            return nil
        }
        
        return contacts
    }
     
    private func isContactsPermissionGranted() -> Bool {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

        switch authorizationStatus {
        case .authorized:
            print("Access to contacts has been granted.")
            return true
        case .denied:
            print("Access to contacts has been denied.")
            return false
        case .restricted:
            print("Access to contacts is restricted.")
            return false
        case .notDetermined:
            // Access has not been determined.
            self.contactStore.requestAccess(for: .contacts) { granted, error in
                if granted {
                    print("Access to contacts was just granted.")
                } else {
                    print("Access to contacts was just denied or there was an error: \(String(describing: error))")
                }
            }
            return false
        @unknown default:
            print("Unknown authorization status.")
            return false
        }
    }
}

extension CNContactStore {
    func askPermissionToAccessContacts() async -> Bool {
        await withCheckedContinuation { continuation in
            self.requestAccess(for: .contacts) { granted, error in
                continuation.resume(with: .success(granted))
            }
        }
    }
}

#Preview {
    TestAppVocalAssistantWrapperView(
        text: "test TestAppVocalAssistantWrapperView",
        size: 15.5,
        buttonLabel: "Start",
        labelSize: 18,
        contactStore: CNContactStore()
    )
}
