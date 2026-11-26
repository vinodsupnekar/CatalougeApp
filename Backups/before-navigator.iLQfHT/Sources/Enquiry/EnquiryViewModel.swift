import SwiftUI

@MainActor
final class EnquiryViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var message = ""
    @Published var isSubmitting = false
    @Published var showThanks = false
    @Published var error: String?

    let product: Product
    private let service: EnquiryService

    init(product: Product, service: EnquiryService = MockEnquiryService()) {
        self.product = product
        self.service = service
    }

    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
            && trimmedEmail.range(
                of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#,
                options: .regularExpression
            ) != nil
            && phone.filter { $0.isNumber }.count >= 8
    }

    func submit() async {
        guard isValid, !isSubmitting else { return }
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        do {
            try await service.submit(
                Enquiry(
                    productID: product.id,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    phone: phone,
                    message: message
                )
            )
            showThanks = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
