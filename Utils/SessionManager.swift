import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: AdminUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        api.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggedIn in
                self?.isLoggedIn = loggedIn
            }
            .store(in: &cancellables)
    }

    func checkAuth() async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await api.getMe()
            currentUser = user
            isLoggedIn = true
        } catch {
            isLoggedIn = false
            currentUser = nil
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await api.login(email: email, password: password)
            currentUser = user
            isLoggedIn = true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() async {
        isLoading = true
        do {
            try await api.logout()
        } catch {
            // ignore logout errors
        }
        isLoggedIn = false
        currentUser = nil
        isLoading = false
    }
}
