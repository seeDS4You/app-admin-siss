import Foundation
import Combine

@MainActor
final class StaffDetailViewModel: ObservableObject {
    @Published var user: AdminUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIClient.shared

    func loadUser(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await api.getStaffDetail(id: id)
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateUser(id: Int, _ request: UpdateUserRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await api.updateUser(id: id, request)
            successMessage = "User updated"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteUser(id: Int) async {
        isLoading = true
        do {
            try await api.deleteUser(id: id)
            successMessage = "User deleted"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword(id: Int) async {
        isLoading = true
        do {
            let resp = try await api.resetPassword(id: id)
            successMessage = resp.message ?? "Password reset"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateRights(id: Int, _ request: UpdateRightsRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            let rights = try await api.updateRights(id: id, request)
            if user != nil {
                user?.rights = rights
            }
            successMessage = "Rights updated"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
