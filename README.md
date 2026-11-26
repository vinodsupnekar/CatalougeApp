# CatalogueApp

SwiftUI catalogue demo for iOS 16+.

## Setup
1. Install/build XcodeGen.
2. Run `xcodegen generate` from this folder.
3. Open CatalogueApp.xcodeproj.
4. Choose the CatalogueApp scheme and an iPhone simulator.
5. Run with Cmd+R; run tests with Cmd+U.

## Features
- Favourite-category selection persisted in UserDefaults.
- Home fetches only selected categories.
- Top five highest-rated products, followed by category sections.
- Search submitted from the keyboard.
- Local JSON search first; full API fetch and title filtering on a miss.
- Product details and demo enquiry form.

## Limitations
- FakeStore has four categories, not ten.
- Top-rated products also appear in their category sections.
- A local search hit returns cached matches only, not every possible remote match.
- JSON storage has no expiry or stale-product deletion.
- Initial category selection requires internet access.
- API outages may prevent loading uncached products.
- Enquiries are simulated; no personal details are sent or persisted.
- Prices are displayed in USD.
- This starter project has not been compiled by the assistant.

## API
https://fakestoreapi.com/products

## Architecture
View -> ViewModel -> ProductRepository -> local JSON / remote API
