//
//  AnalyticsServiceTests.swift
//  AnalyticsServiceTests
//
//  Tests for the AnalyticsService base class.
//

import XCTest
@testable import AnalyticsService

final class AnalyticsServiceTests: XCTestCase {

    var service: AnalyticsService!

    override func setUp() {
        super.setUp()
        service = AnalyticsService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testSharedInstance() {
        // Verify shared instance exists
        XCTAssertNotNil(AnalyticsService.shared)
    }

    func testInitialState() {
        // Without Firebase, isConfigured should be false
        XCTAssertFalse(service.isConfigured)
    }

    func testLogEventDoesNotCrash() {
        // Should not crash even without Firebase
        service.logEvent("test_event")
        service.logEvent("test_event_with_params", parameters: ["key": "value"])
    }

    func testTrackScreenDoesNotCrash() {
        service.trackScreen("TestScreen")
    }

    func testRecordErrorDoesNotCrash() {
        let error = NSError(domain: "test", code: 1, userInfo: nil)
        service.recordError(error)
        service.recordError(error, context: ["key": "value"])
    }

    func testSetUserIdDoesNotCrash() {
        service.setUserId("test-user")
        service.setUserId(nil)
    }

    func testSetUserPropertyDoesNotCrash() {
        service.setUserProperty(name: "tier", value: "premium")
        service.setUserProperty(name: "tier", value: nil)
    }

    func testLogDoesNotCrash() {
        service.log("Test breadcrumb message")
    }

    func testTrackAppOpenDoesNotCrash() {
        service.trackAppOpen()
    }

    func testTrackSignInDoesNotCrash() {
        service.trackSignIn(provider: "apple", isNewUser: true)
        service.trackSignIn(provider: "google", isNewUser: false)
    }

    func testTrackSignOutDoesNotCrash() {
        service.trackSignOut()
    }

    func testTrackPurchaseDoesNotCrash() {
        service.trackPurchase(productId: "premium_monthly", price: 4.99)
        service.trackPurchase(productId: "premium_yearly", price: 29.99, currency: "EUR")
    }

    func testTrackShareDoesNotCrash() {
        service.trackShare(contentType: "photo", itemId: "123")
        service.trackShare(contentType: "article", itemId: "456", method: "twitter")
    }

    func testTrackSearchDoesNotCrash() {
        service.trackSearch(query: "test query", resultsCount: 10)
    }
}
