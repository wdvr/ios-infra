//
//  AnalyticsService.swift
//  AnalyticsService
//
//  Shared Firebase Analytics and Crashlytics integration.
//  Uses conditional compilation to work with or without Firebase dependencies.
//
//  Usage:
//  1. Add this package to your app
//  2. Add Firebase dependencies to your app (optional)
//  3. Call AnalyticsService.shared.configure() in App.init
//  4. Subclass or extend to add app-specific event tracking
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Base analytics service for tracking user behavior and crashes.
/// Subclass this to add app-specific event tracking methods.
open class AnalyticsService: @unchecked Sendable {

    /// Shared instance. Override in subclass if needed.
    public static let shared = AnalyticsService()

    /// Whether Firebase is available and configured
    public private(set) var isConfigured = false

    public init() {}

    // MARK: - Configuration

    /// Configure Firebase. Call this in App.init or AppDelegate.didFinishLaunching.
    open func configure() {
        #if canImport(FirebaseCore)
        // Only configure if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        isConfigured = true
        #endif

        // Enable analytics collection
        #if canImport(FirebaseAnalytics)
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif
    }

    // MARK: - Event Tracking

    /// Log a custom event with optional parameters.
    /// - Parameters:
    ///   - name: Event name (should use snake_case)
    ///   - parameters: Optional dictionary of parameters
    open func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #else
        // Fallback: print to console in debug builds
        #if DEBUG
        print("[Analytics] Event: \(name), params: \(parameters ?? [:])")
        #endif
        #endif
    }

    // MARK: - Screen Tracking

    /// Track a screen view.
    /// - Parameter screenName: Name of the screen being viewed
    open func trackScreen(_ screenName: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
        #else
        #if DEBUG
        print("[Analytics] Screen: \(screenName)")
        #endif
        #endif
    }

    // MARK: - Crash Reporting

    /// Record a non-fatal error for crash reporting.
    /// - Parameters:
    ///   - error: The error to record
    ///   - context: Optional context dictionary for debugging
    open func recordError(_ error: Error, context: [String: Any]? = nil) {
        #if canImport(FirebaseCrashlytics)
        if let context = context {
            for (key, value) in context {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
        Crashlytics.crashlytics().record(error: error)
        #else
        #if DEBUG
        print("[Analytics] Error: \(error), context: \(context ?? [:])")
        #endif
        #endif
    }

    /// Set user identifier for analytics and crash reports.
    /// - Parameter userId: User ID (use anonymized/hashed values for privacy)
    open func setUserId(_ userId: String?) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(userId ?? "")
        #endif

        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(userId)
        #endif
    }

    /// Set a custom user property for segmentation.
    /// - Parameters:
    ///   - name: Property name
    ///   - value: Property value (nil to clear)
    open func setUserProperty(name: String, value: String?) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
    }

    /// Log a breadcrumb message for crash context.
    /// - Parameter message: Message to log
    open func log(_ message: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log(message)
        #else
        #if DEBUG
        print("[Analytics] Log: \(message)")
        #endif
        #endif
    }

    // MARK: - Common Events

    /// Track app open event
    open func trackAppOpen() {
        logEvent("app_open")
    }

    /// Track sign in event
    /// - Parameters:
    ///   - provider: Authentication provider (e.g., "apple", "google", "email")
    ///   - isNewUser: Whether this is a new user signup
    open func trackSignIn(provider: String, isNewUser: Bool) {
        logEvent("sign_in", parameters: [
            "provider": provider,
            "is_new_user": isNewUser
        ])
    }

    /// Track sign out event
    open func trackSignOut() {
        logEvent("sign_out")
    }

    /// Track a purchase or transaction
    /// - Parameters:
    ///   - productId: Product identifier
    ///   - price: Price in currency units
    ///   - currency: Currency code (e.g., "USD")
    open func trackPurchase(productId: String, price: Double, currency: String = "USD") {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterPrice: price,
            AnalyticsParameterCurrency: currency
        ])
        #else
        logEvent("purchase", parameters: [
            "product_id": productId,
            "price": price,
            "currency": currency
        ])
        #endif
    }

    /// Track a share action
    /// - Parameters:
    ///   - contentType: Type of content shared
    ///   - itemId: ID of the shared item
    ///   - method: Share method (e.g., "twitter", "facebook", "copy")
    open func trackShare(contentType: String, itemId: String, method: String? = nil) {
        var params: [String: Any] = [
            "content_type": contentType,
            "item_id": itemId
        ]
        if let method = method {
            params["method"] = method
        }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventShare, parameters: params)
        #else
        logEvent("share", parameters: params)
        #endif
    }

    /// Track search
    /// - Parameters:
    ///   - query: Search query
    ///   - resultsCount: Number of results returned
    open func trackSearch(query: String, resultsCount: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: query,
            "results_count": resultsCount
        ])
        #else
        logEvent("search", parameters: [
            "query": query,
            "results_count": resultsCount
        ])
        #endif
    }
}
