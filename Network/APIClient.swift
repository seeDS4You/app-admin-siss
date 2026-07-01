import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(Int, String)
    case networkError(Error)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .unauthorized: return "Unauthorized. Please log in again."
        case .unknown: return "Unknown error"
        }
    }
}

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "https://allsiss.co.uk/api"
    private let session: URLSession

    @Published var isLoggedIn: Bool = false

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Cookie Helpers
    private func loadCookies() {
        if let cookiesData = UserDefaults.standard.data(forKey: "admin_cookies"),
           let cookies = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cookiesData) as? [HTTPCookie] {
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }

    private func saveCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://allsiss.co.uk")!) {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: "admin_cookies")
            }
        }
    }

    private func clearCookies() {
        UserDefaults.standard.removeObject(forKey: "admin_cookies")
        if let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://allsiss.co.uk")!) {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }

    // MARK: - Request Builder
    private func request(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) -> URLRequest? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body {
            req.httpBody = body
        }
        return req
    }

    // MARK: - Generic Perform
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            saveCookies()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                isLoggedIn = false
                throw APIError.unauthorized
            }

            if (200..<300).contains(httpResponse.statusCode) {
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return decoded
                } catch {
                    throw APIError.decodingError(error)
                }
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(httpResponse.statusCode, errorText)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        do {
            let (_, response) = try await session.data(for: request)
            saveCookies()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                isLoggedIn = false
                throw APIError.unauthorized
            }

            if !(200..<300).contains(httpResponse.statusCode) {
                throw APIError.serverError(httpResponse.statusCode, "Request failed")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Auth
    func login(email: String, password: String) async throws -> AdminUser {
        let body = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        guard let req = request(path: "/auth/login", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        let response: LoginResponse = try await perform(req)
        if let user = response.user {
            isLoggedIn = true
            return user
        } else if let error = response.error {
            throw APIError.serverError(400, error)
        } else {
            throw APIError.unknown
        }
    }

    func logout() async throws {
        guard let req = request(path: "/auth/logout", method: "POST") else {
            throw APIError.invalidURL
        }
        try await performVoid(req)
        isLoggedIn = false
        clearCookies()
    }

    func getMe() async throws -> AdminUser {
        guard let req = request(path: "/auth/me") else { throw APIError.invalidURL }
        let response: LoginResponse = try await perform(req)
        if let user = response.user {
            return user
        } else if let error = response.error {
            throw APIError.serverError(400, error)
        } else {
            throw APIError.unknown
        }
    }

    // MARK: - Dashboard
    func getDashboard() async throws -> DashboardData {
        guard let req = request(path: "/admin/dashboard") else { throw APIError.invalidURL }
        return try await perform(req)
    }

    // MARK: - Events
    func getEvents() async throws -> [EventSummary] {
        guard let req = request(path: "/admin/events") else { throw APIError.invalidURL }
        let resp: EventsResponse = try await perform(req)
        return resp.data
    }

    func getEvent(id: Int) async throws -> Event {
        guard let req = request(path: "/admin/events/\(id)") else { throw APIError.invalidURL }
        let resp: EventResponse = try await perform(req)
        return resp.data
    }

    func createEvent(_ payload: CreateEventRequest) async throws -> Event {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/events", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        let resp: EventResponse = try await perform(req)
        return resp.data
    }

    func updateEvent(id: Int, _ payload: CreateEventRequest) async throws -> Event {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/events/\(id)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        let resp: EventResponse = try await perform(req)
        return resp.data
    }

    func deleteEvent(id: Int) async throws {
        guard let req = request(path: "/admin/events/\(id)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        try await performVoid(req)
    }

    // MARK: - Shifts
    func createShift(_ payload: CreateShiftRequest) async throws -> Shift {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/shifts", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func updateShift(id: Int, _ payload: UpdateShiftRequest) async throws -> Shift {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/shifts/\(id)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func deleteShift(id: Int) async throws {
        guard let req = request(path: "/admin/shifts/\(id)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        try await performVoid(req)
    }

    func allocateShift(shiftId: Int, userId: Int) async throws -> GenericResponse {
        let body = try JSONSerialization.data(withJSONObject: ["user_id": userId])
        guard let req = request(path: "/admin/shifts/\(shiftId)/allocate", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func cancelShift(shiftId: Int) async throws -> GenericResponse {
        guard let req = request(path: "/admin/shifts/\(shiftId)/cancel", method: "POST") else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    // MARK: - Staff / People
    func getStaff() async throws -> [AdminUser] {
        guard let req = request(path: "/admin/users") else { throw APIError.invalidURL }
        let resp: StaffListResponse = try await perform(req)
        return resp.data
    }

    func getStaffDetail(id: Int) async throws -> AdminUser {
        guard let req = request(path: "/admin/users/\(id)") else { throw APIError.invalidURL }
        return try await perform(req)
    }

    func createUser(_ payload: CreateUserRequest) async throws -> AdminUser {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/users", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func updateUser(id: Int, _ payload: UpdateUserRequest) async throws -> AdminUser {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/users/\(id)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func deleteUser(id: Int) async throws {
        guard let req = request(path: "/admin/users/\(id)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        try await performVoid(req)
    }

    func resetPassword(id: Int) async throws -> GenericResponse {
        guard let req = request(path: "/admin/users/\(id)/reset-password", method: "POST") else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func updateRights(id: Int, _ payload: UpdateRightsRequest) async throws -> UserRights {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/users/\(id)/rights", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    // MARK: - Applications
    func getApplications() async throws -> [AdminUser] {
        guard let req = request(path: "/admin/applications") else { throw APIError.invalidURL }
        let resp: StaffListResponse = try await perform(req)
        return resp.data
    }

    func approveApplication(id: Int) async throws -> GenericResponse {
        guard let req = request(path: "/admin/applications/\(id)/approve", method: "POST") else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func rejectApplication(id: Int, reason: String) async throws -> GenericResponse {
        let body = try JSONSerialization.data(withJSONObject: ["reason": reason])
        guard let req = request(path: "/admin/applications/\(id)/reject", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    // MARK: - Doc Approvals
    func getDocApprovals() async throws -> [DocApprovalUser] {
        guard let req = request(path: "/admin/doc-approvals") else { throw APIError.invalidURL }
        let resp: DocApprovalResponse = try await perform(req)
        return resp.data
    }

    func getAllDocuments() async throws -> [DocumentItem] {
        guard let req = request(path: "/admin/documents") else { throw APIError.invalidURL }
        let resp: DocumentsResponse = try await perform(req)
        return resp.data
    }

    func approveDocs(userId: Int) async throws -> GenericResponse {
        guard let req = request(path: "/admin/users/\(userId)/approve-docs", method: "POST") else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func rejectDocs(userId: Int, reason: String) async throws -> GenericResponse {
        let body = try JSONSerialization.data(withJSONObject: ["reason": reason])
        guard let req = request(path: "/admin/users/\(userId)/reject-docs", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func approveDocUpdate(docId: Int) async throws -> GenericResponse {
        guard let req = request(path: "/admin/documents/\(docId)/approve", method: "POST") else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func rejectDocUpdate(docId: Int, reason: String) async throws -> GenericResponse {
        let body = try JSONSerialization.data(withJSONObject: ["reason": reason])
        guard let req = request(path: "/admin/documents/\(docId)/reject", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    // MARK: - QR Scan
    func scanQr(token: String) async -> Result<ScanResponse, APIError> {
        let body = try? JSONSerialization.data(withJSONObject: ["token": token])
        guard let req = request(path: "/admin/scan", method: "POST", body: body) else {
            return .failure(.invalidURL)
        }
        do {
            let (data, response) = try await session.data(for: req)
            saveCookies()

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            if httpResponse.statusCode == 401 {
                isLoggedIn = false
                return .failure(.unauthorized)
            }

            // Try to decode as ScanResponse even on 400/500 for "already signed in" / "invalid QR"
            do {
                let decoded = try JSONDecoder().decode(ScanResponse.self, from: data)
                return .success(decoded)
            } catch {
                if (200..<300).contains(httpResponse.statusCode) {
                    return .failure(.decodingError(error))
                } else {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return .failure(.serverError(httpResponse.statusCode, errorText))
                }
            }
        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - Clients & Invoices
    func getClients() async throws -> [Client] {
        guard let req = request(path: "/admin/clients") else { throw APIError.invalidURL }
        let resp: ClientsResponse = try await perform(req)
        return resp.data
    }

    func getInvoices() async throws -> [Invoice] {
        guard let req = request(path: "/admin/invoices") else { throw APIError.invalidURL }
        let resp: InvoicesResponse = try await perform(req)
        return resp.data
    }

    func createClient(_ payload: CreateClientRequest) async throws -> Client {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/clients", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    func createInvoice(_ payload: CreateInvoiceRequest) async throws -> Invoice {
        let body = try JSONEncoder().encode(payload)
        guard let req = request(path: "/admin/invoices", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await perform(req)
    }

    // MARK: - Timesheets
    func getTimesheets() async throws -> [TimesheetEntry] {
        guard let req = request(path: "/admin/timesheets") else { throw APIError.invalidURL }
        let resp: TimesheetResponse = try await perform(req)
        return resp.data
    }
}
