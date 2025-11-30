import Foundation

// 🔹 This MUST match the App Group ID in Signing & Capabilities
// Go to your app target → Signing & Capabilities → App Groups
// and copy the exact string from the checked row.
let sharedAppGroupID = "group.com.QuotichApp.Quotich"   // <-- replace if yours is different

// 🔹 Shared filename for quotes
let sharedQuotesFilename = "quotes.json"

// 🔹 Key used in UserDefaults to enable/disable daily widget quotes
let widgetEnabledKey = "widgetDailyQuotesEnabled"
