# Decisions and Assumptions

## Scope

CatalogueApp is a SwiftUI catalogue proof of concept using FakeStore API,
local product storage, favourite categories, search, product details, and a
demo enquiry form.

## Assumptions where acceptance criteria were unclear

### Architecture terminology

“MVVP” was interpreted as MVVM because the requirements explicitly describe
a ViewModel layer.

### Category count

The requirement specifies ten categories. FakeStore provides four categories,
so the app displays actual API categories rather than inventing unsupported
ones. Meeting the ten-category requirement needs another data source or an
agreed category mapping.

### Favourite meaning

Favourites means favourite categories, not favourite individual products.
Selections are persisted in UserDefaults.

### Top-rated products

Top Rated means the five highest-rated products within selected categories.
Products are sorted by rating score, then rating count, then product ID.

These products also appear in their category sections. Top Rated is a featured
section, not an exclusive partition.

### Search

Search matches product titles case-insensitively and ignores surrounding
whitespace. It starts when the user submits from the keyboard.

A local match returns cached results immediately. A local miss triggers a full
API fetch, persistence, and title filtering.

This follows the requested fallback behaviour but can return incomplete results
when only part of the catalogue is cached.

### Navigation

Navigator decides whether to show category selection or Home and manages Home's
navigation path for Search, category lists, and product details.

Favourite editing restores saved selections into a draft. Continue persists the
draft; Cancel discards it. Cancel is unavailable during first-launch onboarding.

Root-screen switching recreates Home and resets its navigation stack. This is
not a tab-bar implementation.

### Enquiry

No enquiry endpoint was provided. Submission is simulated, with a thank-you
alert explicitly identifying the demo behaviour. Contact details are neither
sent nor persisted.

### Platform and currency

The project targets iOS 16+. Product prices are displayed in USD.

## Requirements dropped or simplified, and why

- **Ten categories:** reduced to API-supported categories because the selected
  backend does not supply ten.
- **Real enquiry delivery:** omitted because no backend contract, consent,
  authentication, or retention requirements were supplied.
- **Local persistence:** uses a JSON file in Application Support rather than
  a database because the demo catalogue is small.
- **Image management:** uses AsyncImage without a dedicated caching or
  prefetching implementation.
- **Offline support:** provides cached-product fallback for Home, but initial
  category selection still requires network access.
- **Search completeness:** follows local-hit/local-miss rules instead of always
  refreshing or using server-side search.
- **Production operations:** authentication, analytics, monitoring,
  localisation, and a formal accessibility audit are outside this PoC.

The JSON cache merges products by ID but has no expiry, migrations, indexing,
or stale-record deletion.

## How the design supports growth beyond the PoC

### Separation of concerns

```text
View -> ViewModel -> Repository -> Local / Remote data source
```

Views render presentation state. ViewModels manage loading, validation, and
errors. Repositories define retrieval policy. Data sources handle persistence
and networking.

ViewModels are in separate files, and Product-related models, data types, and
reusable views are grouped together.

### Replaceable dependencies

Protocol-based repositories and data sources allow the application to:

- Replace FakeStore with an approved catalogue API.
- Replace JSON persistence with SwiftData, Core Data, or SQLite.
- Inject test doubles without making real network requests.
- Replace the mock enquiry service with a real implementation.

Larger APIs would also require pagination, DTO-to-domain mapping, structured
errors, authentication, cache invalidation, and regional content rules.

### Navigation

Explicit Navigator actions provide a foundation for deep links, additional
features, and coordinated navigation. Restorable navigation and modal/tab
coordination remain future work.

### Production readiness

Production adoption would require approved privacy and security controls,
accessibility validation, CI, observability, dependency review, and
comprehensive automated tests.

## What I would do next with another day

Prioritised work:

1. Compile the project in the target Xcode version, run existing tests, and fix
   build/runtime issues.
2. Add Navigator tests and repository coverage for API failures, offline
   fallback, selected-category requests, and search refresh.
3. Add UI smoke tests for onboarding, editing/cancelling favourites, Search,
   product details, and enquiry validation.
4. Improve error and empty states, loading feedback, accessibility labels, and
   Dynamic Type behaviour.
5. Define a cache expiry strategy and document search completeness trade-offs.
6. Establish a CI build/test workflow and confirm XcodeGen compatibility.

With additional time, replace JSON storage with indexed persistence, introduce
image caching, and agree a real enquiry API contract before implementation.
