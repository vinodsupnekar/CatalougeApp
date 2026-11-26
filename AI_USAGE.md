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
