#!/bin/bash
set -euo pipefail

if [ ! -f project.yml ]; then
    echo "Run this script from the CatalogueApp project root."
    exit 1
fi

# Back up existing documentation before replacing it.
if [ -f DECISIONS.md ] || [ -f AI_USAGE.md ]; then
    mkdir -p Backups
    BACKUP_DIR="$(mktemp -d Backups/docs.XXXXXX)"

    for file in DECISIONS.md AI_USAGE.md; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_DIR/"
        fi
    done

    echo "Existing documentation backed up to: $BACKUP_DIR"
fi

cat > DECISIONS.md <<'EOF'
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
EOF

cat > AI_USAGE.md <<'EOF'
# AI Usage Notes

## Tools and models used

A conversational AI assistant, presented as Helix, helped produce:

- SwiftUI and MVVM scaffolding.
- Repository and data-source implementations.
- XcodeGen configuration and setup scripts.
- Starter repository tests.
- Feature-based file restructuring.
- Navigator-based favourites and Search routing.
- Documentation and Terminal instructions.

The underlying model name/version was not exposed in this conversation and
cannot be recorded reliably.

GitHub tools were used to inspect the accessible `getndazn/XcodeGen` repository
and its tags. XcodeGen, shell scripts, Python 3, and nano were included in the
local setup workflow.

Xcode and iOS Simulator were recommended for validation. The AI did not execute
Xcode, compile the application, or run its tests. No successful local build or
test results were supplied in the conversation.

## Agent instruction files

No project-specific agent instruction files were supplied or generated during
this conversation, including:

- CLAUDE.md
- AGENTS.md
- .cursor/rules

This is a statement about the AI-assisted work, not an independent audit of the
repository. If instruction files are added, commit and document them here.

## Plan or specification

The user's numbered acceptance criteria served as the initial specification.
No separate formal plan was created before implementation.

The main requirements were:

1. Favourite-category selection at launch.
2. Relevant-category product fetching for Home.
3. Top-rated products followed by category sections.
4. Local-first title search with full API refresh on a local miss.
5. Repository pattern and MVVM.
6. Product details and an enquiry form.
7. Local persistence for the PoC.

Later requests introduced separate ViewModel files, Product-focused folders,
and Navigator-driven favourites/Search routing.

DECISIONS.md records the resulting assumptions and simplifications.

## Key prompts or moments that shaped the solution

1. **Initial catalogue requirements:** established SwiftUI, MVVM, Repository
   pattern, FakeStore API, local search fallback, and enquiry behaviour.

2. **Request for a runnable iOS project:** shifted delivery to an XcodeGen
   configuration and shell scripts that create source files locally.

3. **Request to separate ViewModels and group Product types:** introduced
   feature-oriented folders and dedicated ViewModel files.

4. **Request to restore favourite selections through Navigator:** replaced the
   reset-based flow with draft editing, explicit Continue/Cancel actions, and
   saved-selection restoration.

5. **Request to move Search into Navigator:** introduced a shared navigation
   path for Search and product/category destinations.

## Where AI got something wrong, and how it was caught

### Favourites originally cleared saved selections

The initial Favourites button saved an empty selection and replaced Home with
category selection. This lost previous choices.

The user requested restored selections and Navigator-driven routing. The design
was revised to edit a draft and persist only on Continue.

### Navigator script depended on exact formatting

The generated add-navigator.sh matched an exact multiline button implementation.
It failed when the user's HomeView differed:

```text
HomeView's Favourites button differs from the expected code.
No files have been changed.
```

This was caught when the user executed the script and reported the output.
The safeguard prevented partial changes. Manual adaptation was recommended.

The subsequent suggestion to paste an “exact” replacement could still fail if
indentation differed. A syntax-aware or whitespace-tolerant update would be more
robust.

### Ten categories could not be delivered by the selected API

The requested ten-category screen conflicted with FakeStore's four-category
catalogue. The assistant identified this during design and documented a
simplification rather than fabricating categories. This remains an acceptance
gap, not a completed ten-category requirement.

### Runtime validation was unavailable

Generated code and XcodeGen instructions were not compiled or tested by the AI.
Compatibility with the user's Xcode, Swift, and internal XcodeGen fork remains
a local validation responsibility.

No specific compile failures or passing tests should be claimed without actual
build/test output.

### Enquiry success needed explicit demo wording

The first generated thank-you message implied an enquiry had been received,
despite using a mock service. Later generated files made the mock status explicit:
no enquiry is sent and no contact details are persisted.

## Human review and validation

Before treating the project as complete:

- Compile and run using the intended Xcode version.
- Execute tests and record results.
- Verify navigation, favourite restoration, and Cancel behaviour.
- Test offline loading, API errors, and local-first search limitations.
- Review accessibility, privacy, security, and public API usage terms.
- Replace demo services only after agreeing approved backend contracts.
- Review generated scripts before executing them.

## Confidentiality

Do not place credentials, customer information, production secrets, or sensitive
internal data in AI prompts, source code, documentation, or Git history.

Use approved secret-management and configuration mechanisms for real services.
EOF

echo
echo "Created:"
echo "  DECISIONS.md"
echo "  AI_USAGE.md"
echo "No Xcode project regeneration is required."
