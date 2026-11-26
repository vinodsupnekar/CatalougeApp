#!/bin/bash
set -euo pipefail

# Run from the project root.
if [ ! -f project.yml ] || [ ! -f Sources/Home/HomeView.swift ]; then
    echo "Run this script from the CatalogueApp project root."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 is required to update HomeView safely."
    exit 1
fi

# Validate HomeView before making changes.
python3 - <<'PY'
from pathlib import Path

path = Path("Sources/Home/HomeView.swift")
text = path.read_text()

original = """Button("Favourites") {
                        container.saveFavorites([])
                    }"""

updated = """Button("Favourites") {
                        container.handle(.editFavourites)
                    }"""

if original not in text and updated not in text:
    raise SystemExit(
        "HomeView's Favourites button differs from the expected code.\n"
        "No files have been changed. Restore the original button or "
        "update it manually before running this script."
    )

if "showEditCategoriesConfirmation" in text:
    raise SystemExit(
        "Remove the previous edit-category confirmation dialog first.\n"
        "No files have been changed."
    )
PY

# Keep backups outside Sources to prevent duplicate Swift definitions.
mkdir -p Backups
BACKUP_DIR="$(mktemp -d Backups/before-navigator.XXXXXX)"
cp -R Sources "$BACKUP_DIR/Sources"

echo "Backup created: $BACKUP_DIR/Sources"

mkdir -p Sources/App Sources/Category

######################## NAVIGATOR ########################

cat > Sources/App/Navigator.swift <<'SWIFT'
import SwiftUI

@MainActor
final class Navigator: ObservableObject {
    enum Screen {
        case favourites
        case home
    }

    enum Action {
        case launch
        case editFavourites
        case continueWithFavourites([String])
        case cancelFavourites
    }

    @Published private(set) var screen: Screen = .favourites

    func handle(_ action: Action, savedFavourites: [String]) {
        switch action {
        case .launch, .cancelFavourites:
            screen = savedFavourites.isEmpty ? .favourites : .home

        case .editFavourites:
            screen = .favourites

        case .continueWithFavourites(let categories):
            screen = categories.isEmpty ? .favourites : .home
        }
    }
}
SWIFT

######################## APP CONTAINER ########################

cat > Sources/App/AppContainer.swift <<'SWIFT'
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let repository: ProductRepository
    let navigator: Navigator

    @Published private(set) var favorites: [String]

    private let store: FavoritesStore

    init() {
        let store = FavoritesStore()
        let savedFavorites = store.load()

        self.store = store
        favorites = savedFavorites

        repository = DefaultProductRepository(
            remote: FakeStoreAPI(),
            local: FileProductStore()
        )

        let navigator = Navigator()
        self.navigator = navigator

        navigator.handle(
            .launch,
            savedFavourites: savedFavorites
        )
    }

    func handle(_ action: Navigator.Action) {
        if case .continueWithFavourites(let categories) = action {
            let selection = Array(Set(categories)).sorted()
            guard !selection.isEmpty else { return }

            store.save(selection)
            favorites = selection
        }

        navigator.handle(
            action,
            savedFavourites: favorites
        )
    }
}
SWIFT

######################## APP ENTRY ########################

cat > Sources/App/CatalogueApp.swift <<'SWIFT'
import SwiftUI

@main
struct CatalogueApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(container.navigator)
        }
    }
}
SWIFT

######################## ROOT VIEW ########################

cat > Sources/App/RootView.swift <<'SWIFT'
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var navigator: Navigator

    private var cancelAction: (() -> Void)? {
        guard !container.favorites.isEmpty else { return nil }

        return {
            container.handle(.cancelFavourites)
        }
    }

    var body: some View {
        switch navigator.screen {
        case .favourites:
            CategorySelectionView(
                vm: CategorySelectionViewModel(
                    repo: container.repository,
                    selectedCategories: container.favorites
                ),
                onContinue: { categories in
                    container.handle(
                        .continueWithFavourites(categories)
                    )
                },
                onCancel: cancelAction
            )

        case .home:
            HomeView(
                vm: HomeViewModel(
                    repo: container.repository,
                    favorites: container.favorites
                )
            )
            .id(container.favorites.joined(separator: "|"))
        }
    }
}
SWIFT

######################## CATEGORY VIEWMODEL ########################

cat > Sources/Category/CategorySelectionViewModel.swift <<'SWIFT'
import SwiftUI

@MainActor
final class CategorySelectionViewModel: ObservableObject {
    @Published var categories: [String] = []
    @Published var selected: Set<String>
    @Published var isLoading = false
    @Published var error: String?

    private let repo: ProductRepository

    init(
        repo: ProductRepository,
        selectedCategories: [String] = []
    ) {
        self.repo = repo
        selected = Set(selectedCategories)
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            categories = try await repo.categories()

            // Remove unsupported categories from the draft only.
            // Saved favourites remain unchanged until Continue.
            selected.formIntersection(Set(categories))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggle(_ category: String) {
        if selected.contains(category) {
            selected.remove(category)
        } else {
            selected.insert(category)
        }
    }
}
SWIFT

######################## CATEGORY VIEW ########################

cat > Sources/Category/CategorySelectionView.swift <<'SWIFT'
import SwiftUI

struct CategorySelectionView: View {
    @StateObject var vm: CategorySelectionViewModel

    let onContinue: ([String]) -> Void
    var onCancel: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose your favourite categories")
                    .font(.title2.bold())

                Text("We’ll show products from these categories.")
                    .foregroundStyle(.secondary)

                if vm.isLoading {
                    ProgressView("Loading categories…")
                }

                if let error = vm.error {
                    Text(error)
                        .foregroundStyle(.red)

                    Button("Retry") {
                        Task { await vm.load() }
                    }
                }

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 145))
                        ],
                        spacing: 12
                    ) {
                        ForEach(vm.categories, id: \.self) { category in
                            Button {
                                vm.toggle(category)
                            } label: {
                                VStack(spacing: 10) {
                                    Image(
                                        systemName: vm.selected.contains(category)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                    )

                                    Text(category.capitalized)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: 100
                                )
                                .foregroundStyle(
                                    vm.selected.contains(category)
                                    ? Color.white
                                    : Color.primary
                                )
                                .background(
                                    vm.selected.contains(category)
                                    ? Color.accentColor
                                    : Color(
                                        uiColor: .secondarySystemBackground
                                    )
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 14)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(category)
                            .accessibilityValue(
                                vm.selected.contains(category)
                                ? "Selected"
                                : "Not selected"
                            )
                        }
                    }
                }

                Button("Continue") {
                    onContinue(vm.selected.sorted())
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    vm.selected.isEmpty
                    || vm.isLoading
                    || vm.categories.isEmpty
                    || vm.error != nil
                )
            }
            .padding()
            .navigationTitle("Top Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if let onCancel = onCancel {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }
            }
            .task {
                await vm.load()
            }
        }
    }
}
SWIFT

######################## UPDATE HOME BUTTON ########################

python3 - <<'PY'
from pathlib import Path

path = Path("Sources/Home/HomeView.swift")
text = path.read_text()

original = """Button("Favourites") {
                        container.saveFavorites([])
                    }"""

updated = """Button("Favourites") {
                        container.handle(.editFavourites)
                    }"""

path.write_text(text.replace(original, updated))
print("Home Favourites button updated.")
PY

######################## IGNORE BACKUPS ########################

touch .gitignore

if ! grep -qxF 'Backups/' .gitignore; then
    printf '\nBackups/\n' >> .gitignore
fi

echo
echo "Navigator integration complete."
echo "Backup: $BACKUP_DIR/Sources"
echo
echo "Next:"
echo "  xcodegen generate"
echo "  open CatalogueApp.xcodeproj"

