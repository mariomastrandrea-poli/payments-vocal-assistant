//
//  IntentAndEntitiesExtractorTests.swift
//  PaymentsVocalAssistantTests
//
//  Created by Mario Mastrandrea on 24/01/24.
//

import XCTest
@testable import PaymentsVocalAssistant

final class IntentAndEntitiesExtractorTests: XCTestCase {
    var originalLogFlagValue: Bool!
    var vocalAssistant: PaymentsVocalAssistant!
    
    
    override func setUp() async throws {
        // disable flag
        self.originalLogFlagValue = GlobalConfig.enableLogs
        GlobalConfig.enableLogs = false
        
        let vocalAssistant = await PaymentsVocalAssistant.instance(appContext: AppContext(userContacts: [AppDelegateStub.antonioRossiContact, AppDelegateStub.giuseppeVerdiContact], userBankAccounts: [AppDelegateStub.futureBankAccount, AppDelegateStub.topBankAccount]))
        XCTAssertNotNil(vocalAssistant, "Failed to initialize PaymentsVocalAssistant")
        self.vocalAssistant = vocalAssistant!
    }
    
    override func tearDownWithError() throws {
        // reset flag
        GlobalConfig.enableLogs = self.originalLogFlagValue
    }
    
    private func createExtractedIntentAndEntitiesTest(for sample: ExtractorSample) {
        let dialogueManager = self.vocalAssistant.newConversation(withMessage: "", andDefaultErrorMessage: "", maxNumOfLastTransactions: 5, appDelegate: AppDelegateStub())

        let intentAndEntitiesExtractor = dialogueManager.dst.intentAndEntitiesExtractor
        let recognitionOutput = intentAndEntitiesExtractor.recognize(from: sample.text)
        XCTAssert(recognitionOutput.isSuccess)
        
        let prediction = recognitionOutput.success!
        
        // check predicted intent
        XCTAssertEqual(prediction.predictedIntent.type, sample.intent)
        
        // check predicted entities type
        XCTAssertEqual(prediction.predictedEntities.map { $0.type }, sample.entities)
    }
    
    func testEntities() throws {
        let sample = ExampleText._3
        let conversationManager = self.vocalAssistant.newConversation(withMessage: "", andDefaultErrorMessage: "", maxNumOfLastTransactions: 5, appDelegate: AppDelegateStub())

        let intentAndEntitiesExtractor = conversationManager.dst.intentAndEntitiesExtractor
        let recognitionOutput = intentAndEntitiesExtractor.recognize(from: sample.text)
        XCTAssert(recognitionOutput.isSuccess)
        
        let prediction = recognitionOutput.success!
        
        print("\"\(sample.text)\"")
        print(prediction.predictedIntent)
        prediction.predictedEntities.forEach { print($0) }
    }
    

    func testExtractedIntentAndEntities() throws {
        createExtractedIntentAndEntitiesTest(for: ExampleText.cic)
        createExtractedIntentAndEntitiesTest(for: ExampleText._1)
        createExtractedIntentAndEntitiesTest(for: ExampleText._2)
        createExtractedIntentAndEntitiesTest(for: ExampleText._3)
    }
}
