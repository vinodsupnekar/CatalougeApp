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
