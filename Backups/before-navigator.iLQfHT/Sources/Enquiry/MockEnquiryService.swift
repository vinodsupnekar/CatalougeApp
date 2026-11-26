import Foundation

// Demo only: no network request and no contact details are persisted.
struct MockEnquiryService: EnquiryService {
    func submit(_ enquiry: Enquiry) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
