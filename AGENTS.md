# AGENTS.md — Quotich iOS (Memmi)

## Project Overview
iOS app for storing, searching, and surfacing quotes. Built in Swift/SwiftUI.
- Main app: quote storage, search, daily resurfacing
- Widget targets: QuoteOfTheDay, Quotie widget extensions
- Backend: Supabase (client in `SupabaseClientProvider.swift`)
- AI responses: OpenAI API (`AppConfig.swift` — read for context, never modify or print contents)

## Targets
- `Quotie` — main iOS app
- `QuoteOfTheDayWidgetExtension` — home screen widget
- `QuotieWidgetExtension` — additional widget

## Build Command (no signing required for verification)
```bash
xcodebuild -project Quotie.xcodeproj \
  -scheme Quotie \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|warning:|BUILD"
```

## Sensitive Files — Read-Only, Never Print Contents
- `AppConfig.swift` — API keys
- `SupabaseClientProvider.swift` — Supabase credentials
- `*.entitlements` — signing
- `Quotie.xcodeproj/project.pbxproj` — do not modify signing section

## Branch Convention
`feature/short-description` — always branch off main, never push to main directly.
