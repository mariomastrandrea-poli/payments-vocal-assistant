//
//  PaymentsVocalAssistantDelegate.swift
//  PaymentsVocalAssistant
//
//  Created by Mario Mastrandrea on 02/02/24.
//

import Foundation

/** Interface of the App Delegate in charge of actually performing the operations requested by the user to the `PaymentsVocalAssistant` */
public protocol PaymentsVocalAssistantDelegate {
    
    /** 
    Check the user's balance for a specific bank account
    - parameter bankAccount: the specific bank account whose balance has to be checked
    - returns: the requested amount
    */
    func performInAppCheckBalanceOperation(for bankAccount: VocalAssistantBankAccount) async throws -> VocalAssistantAmount
    
    /**
     Check the user's last transactions, eventually involving a specific bank account and/or a specific contact
     - parameter bankAccount: the specific bank account whose last transactions have to be checked
     - parameter contact: the specific contact whose last transactions have to be checked
     - returns: the list of the requested transactions
     */
    func performInAppCheckLastTransactionsOperation(for bankAccount: VocalAssistantBankAccount?, involving contact: VocalAssistantContact?) async throws -> [VocalAssistantTransaction]
    
    /**
     Send an amount of money to a specific contact, using a specified user's bank account
     - parameter amount: the amount which has to be sent in the transaction
     - parameter receiver: the contact who will receive the money
     - parameter bankAccount: the user's bank account where the money has to be taken from
     - returns: a boolean indicating if the transaction was successful or not, and an associated error message, if any
     */
    func performInAppSendMoneyOperation(amount: VocalAssistantAmount, to receiver: VocalAssistantContact, using bankAccount: VocalAssistantBankAccount) async throws -> (success: Bool, errorMsg: String?)
    
    /**
     Request an amount of money to a specific contact, using a specified user's bank account
     - parameter amount: the amount of money requested
     - parameter sender: the contact who will be requested the money from
     - parameter bankAccount: the user's bank account where the money will be delivered, if the transaction will be successful
     - returns: a boolean indicating if the request has been successfully sent or not, and an associated error message, if any
     */
    func performInAppRequestMoneyOperation(amount: VocalAssistantAmount, from sender: VocalAssistantContact, using bankAccount: VocalAssistantBankAccount) async throws -> (success: Bool, errorMsg: String?)
}

