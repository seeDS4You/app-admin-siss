import Foundation
import Combine

@MainActor
final class DocumentsViewModel: ObservableObject {
    @Published var pendingDocs: [DocApprovalUser] = []
    @Published var allDocuments: [DocumentItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIClient.shared

    func loadPendingDocs() async {
        isLoading = true
        errorMessage = nil
        do {
            pendingDocs = try await api.getDocApprovals()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadAllDocuments() async {
        isLoading = true
        errorMessage = nil
        do {
            allDocuments = try await api.getAllDocuments()
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
            await loadPendingDocs()
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
            await loadPendingDocs()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approveDocUpdate(docId: Int) async {
        isLoading = true
        do {
            let resp = try await api.approveDocUpdate(docId: docId)
            successMessage = resp.message ?? "Approved"
            await loadAllDocuments()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func rejectDocUpdate(docId: Int, reason: String) async {
        isLoading = true
        do {
            let resp = try await api.rejectDocUpdate(docId: docId, reason: reason)
            successMessage = resp.message ?? "Rejected"
            await loadAllDocuments()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
