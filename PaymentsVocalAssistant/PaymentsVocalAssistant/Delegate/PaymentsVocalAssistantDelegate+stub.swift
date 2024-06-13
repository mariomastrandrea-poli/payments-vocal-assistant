//
//  PaymentsVocalAssistantDelegate+stub.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 13/06/24.
//

import Foundation


public class AppDelegateStub: PaymentsVocalAssistantDelegate {
    // * currencies *
    
    public static let dollarCurrency = VocalAssistantCurrency(id: "$", symbols: ["$", "USD"], literals: ["dollar", "buck", "USD", "US dollar"])
    public static let aedCurrency = VocalAssistantCurrency(id: "AED", symbols: ["AED"], literals: ["dirham"])
    
    public static let defaultCurrencies = [
        dollarCurrency,
        aedCurrency
    ]
    
    // * bank account *
    
    public static let topBankAccount = VocalAssistantBankAccount(id: "1", name: "Top Bank", default: true, currency: dollarCurrency)
    public static let futureBankAccount = VocalAssistantBankAccount(id: "2", name: "Future Bank", default: false, currency: aedCurrency)
    
    public static let defaultBankAccounts = [
        topBankAccount: 2350.68,
        futureBankAccount: 5126.49
    ]
    
    // * contacts *
    
    public static let antonioRossiContact = VocalAssistantContact(id: "01234567", firstName: "Antonio", lastName: "Rossi")
    public static let giuseppeVerdiContact = VocalAssistantContact(id: "12333444", firstName: "Giuseppe", lastName: "Verdi")
    
    public static let defaultContacts = [
        antonioRossiContact,
        giuseppeVerdiContact
    ]
    
    // * transactions *
    
    public static let defaultLastTransactions: [VocalAssistantTransaction] = [
        VocalAssistantTransaction(
            amount: VocalAssistantAmount(
                value: 20.5,
                currency: AppDelegateStub.dollarCurrency
            ),
            contact: AppDelegateStub.antonioRossiContact,
            bankAccount: AppDelegateStub.topBankAccount,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        VocalAssistantTransaction(
            amount: VocalAssistantAmount(
                value: -17.0,
                currency: AppDelegateStub.aedCurrency
            ),
            contact: AppDelegateStub.giuseppeVerdiContact,
            bankAccount: AppDelegateStub.futureBankAccount,
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        ),
        VocalAssistantTransaction(
            amount: VocalAssistantAmount(
                value: 2.50,
                currency: AppDelegateStub.dollarCurrency
            ),
            contact: AppDelegateStub.giuseppeVerdiContact,
            bankAccount: AppDelegateStub.topBankAccount,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        ),
        VocalAssistantTransaction(
            amount: VocalAssistantAmount(
                value: 49.89,
                currency: AppDelegateStub.dollarCurrency
            ),
            contact: AppDelegateStub.antonioRossiContact,
            bankAccount: AppDelegateStub.topBankAccount,
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        ),
        VocalAssistantTransaction(
            amount: VocalAssistantAmount(
                value: -20.50,
                currency: AppDelegateStub.dollarCurrency
            ),
            contact: AppDelegateStub.giuseppeVerdiContact,
            bankAccount: AppDelegateStub.topBankAccount,
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        ),
        VocalAssistantTransaction(
            amount: VocalAssistantAmount(
                value: -7.80,
                currency: AppDelegateStub.aedCurrency
            ),
            contact: AppDelegateStub.antonioRossiContact,
            bankAccount: AppDelegateStub.futureBankAccount,
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        )
    ]
    
    
    // instance properties
    public let contacts: [VocalAssistantContact]
    public var bankAccounts: [VocalAssistantBankAccount: Double]
    public var lastTransactions: [VocalAssistantTransaction]

    
    public init(
        contacts: [VocalAssistantContact] = defaultContacts,
        bankAccounts: [VocalAssistantBankAccount: Double] = defaultBankAccounts,
        transactions: [VocalAssistantTransaction] = defaultLastTransactions
    ) {
        self.contacts = contacts
        self.bankAccounts = bankAccounts
        self.lastTransactions = transactions
    }
    
    public func performInAppCheckBalanceOperation(for bankAccount: VocalAssistantBankAccount) async throws -> VocalAssistantAmount {
        
        let bankAccountSearchResult = self.bankAccounts.first { (b, amount) in
            b.id == bankAccount.id
        }
                
        guard let (_, amount) = bankAccountSearchResult else {
            throw StubError(errorMsg: "\(bankAccount.name) bank account not found.")
        }
        
        logInfo("App delegate stub performed check balance: \(amount.description)")
        return VocalAssistantAmount(value: amount, currency: bankAccount.currency)
    }
    
    public func performInAppCheckLastTransactionsOperation(for bankAccount: VocalAssistantBankAccount?, involving contact: VocalAssistantContact?) async throws -> [VocalAssistantTransaction] {
        
        let fakeTransactions = self.lastTransactions.filter { transaction in
            (bankAccount != nil ? transaction.bankAccount.id == bankAccount!.id : true) &&
            (contact != nil ? transaction.contact.id == contact!.id : true)
        }
        
        return fakeTransactions
    }
    
    public func performInAppSendMoneyOperation(amount: VocalAssistantAmount, to receiver: VocalAssistantContact, using bankAccount: VocalAssistantBankAccount) async throws -> (success: Bool, errorMsg: String?) {
        
        guard let bankAccountAmount = self.bankAccounts[bankAccount] else {
            throw StubError(errorMsg: "\(bankAccount.name) bank account not found.")
        }
        
        guard self.contacts.contains(where: { c in c.id == receiver.id }) else {
            throw StubError(errorMsg: "\(receiver) contact not found.")
        }
        
        guard bankAccount.currency == amount.currency else {
            throw StubError(errorMsg: "\(bankAccount.name) account is in \(bankAccount.currency.literalPlural) while the \(amount.descriptionWithoutSign) amount is in \(amount.currency.literalPlural).")
        }
        
        guard bankAccountAmount >= amount.value else {
            return (success: false, errorMsg: "You don't have enough credit in your \(bankAccount.name) account (\(VocalAssistantAmount(value: bankAccountAmount, currency: bankAccount.currency)))")
        }
        
        // save transaction, subtract funds, and return successful outcome
        
        let transaction = VocalAssistantTransaction(
            amount: amount.value <= 0 ? amount : VocalAssistantAmount(
                value: -1 * amount.value,
                currency: amount.currency
            ),
            contact: receiver,
            bankAccount: bankAccount,
            date: Date()
        )
        self.lastTransactions.append(transaction)
        self.bankAccounts[bankAccount] = bankAccountAmount - abs(amount.value)
        
        return (success: true, errorMsg: nil)
    }
    
    public func performInAppRequestMoneyOperation(amount: VocalAssistantAmount, from sender: VocalAssistantContact, using bankAccount: VocalAssistantBankAccount) async throws -> (success: Bool, errorMsg: String?) {
        
        guard let bankAccountAmount = self.bankAccounts[bankAccount] else {
            throw StubError(errorMsg: "\(bankAccount.name) bank account not found.")
        }
        
        guard self.contacts.contains(where: { c in c.id == sender.id }) else {
            throw StubError(errorMsg: "\(sender) contact not found.")
        }
        
        guard bankAccount.currency == amount.currency else {
            throw StubError(errorMsg: "\(bankAccount.name) account is in \(bankAccount.currency.literalPlural) while the \(amount.descriptionWithoutSign) amount is in \(amount.currency.literalPlural).")
        }
        
        // save transaction, add funds, and return successful outcome
        
        let transaction = VocalAssistantTransaction(
            amount: amount.value >= 0 ? amount : VocalAssistantAmount(
                value: -1 * amount.value,
                currency: amount.currency
            ),
            contact: sender,
            bankAccount: bankAccount,
            date: Date()
        )
        self.lastTransactions.append(transaction)
        self.bankAccounts[bankAccount] = bankAccountAmount + abs(amount.value)
        
        return (success: true, errorMsg: nil)
    }
}

public struct StubError: Error, CustomStringConvertible {
    public let errorMsg: String
    
    public var description: String {
        return self.errorMsg
    }
    
    public init(errorMsg: String) {
        self.errorMsg = errorMsg
    }
}

