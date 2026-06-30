import Foundation
import Combine

@MainActor
final class PeopleViewModel: ObservableObject {
    @Published var applications: [AdminUser] = []
    @Published var staff: [AdminUser] = []
    @Published var docApprovals: [DocApprovalUser] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIClient.shared

    func loadApplications() async {
        isLoading = true
        errorMessage = nil
        do {
            applications = try await api.getApplications()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadStaff() async {
        isLoading = true
        errorMessage = nil
        do {
            staff = try await api.getStaff()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadDocApprovals() async {
        isLoading = true
        errorMessage = nil
        do {
            docApprovals = try await api.getDocApprovals()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approveApplication(id: Int) async {
        isLoading = true
        do {
            let resp = try await api.approveApplication(id: id)
            successMessage = resp.message ?? "Approved"
            await loadApplications()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func rejectApplication(id: Int, reason: String) async {
        isLoading = true
        do {
            let resp = try await api.rejectApplication(id: id, reason: reason)
            successMessage = resp.message ?? "Rejected"
            await loadApplications()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approveDocs(userId: Int) async {
        isLoading = true
        do {
            let resp = try await api.approveDocs(userId: userId)
            successMessage = resp.message ?? "Approved"
            await loadDocApprovals()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func rejectDocs(userId: Int, reason: String) async {
        isLoading = true
        do {
            let resp = try await api.rejectDocs(userId: userId, reason: reason)
            successMessage = resp.message ?? "Rejected"
            await loadDocApprovals()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createUser(_ request: CreateUserRequest) async -> AdminUser? {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await api.createUser(request)
            successMessage = "User created"
            await loadStaff()
            return user
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        return nil
    }
}
