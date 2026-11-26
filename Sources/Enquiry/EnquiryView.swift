import SwiftUI

struct EnquiryView: View {
    @StateObject var vm: EnquiryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Demo form: no enquiry will be sent.")
                        .foregroundStyle(.secondary)
                }

                Section("Product") {
                    Text(vm.product.title)
                }

                Section("Contact details") {
                    TextField("Full name", text: $vm.name)
                        .textContentType(.name)
                    TextField("Email", text: $vm.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $vm.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Message (optional)") {
                    TextField("Your enquiry", text: $vm.message, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = vm.error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        HStack {
                            Text(vm.isSubmitting ? "Submitting…" : "Submit")
                            if vm.isSubmitting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(!vm.isValid || vm.isSubmitting)
                }
            }
            .navigationTitle("Enquiry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(vm.isSubmitting)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
            .interactiveDismissDisabled(vm.isSubmitting)
            .alert("Thank you!", isPresented: $vm.showThanks) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your demo enquiry is complete. No enquiry was sent.")
            }
        }
    }
}
