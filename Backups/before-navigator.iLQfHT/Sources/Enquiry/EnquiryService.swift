import Foundation

protocol EnquiryService {
    func submit(_ enquiry: Enquiry) async throws
}
