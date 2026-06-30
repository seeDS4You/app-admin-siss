import Foundation
import Combine

@MainActor
final class FinanceViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var invoices: [Invoice] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIClient.shared

    func loadClients() async {
        isLoading = true
        errorMessage = nil
        do {
            clients = try await api.getClients()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadInvoices() async {
        isLoading = true
        errorMessage = nil
        do {
            invoices = try await api.getInvoices()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createClient(_ request: CreateClientRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await api.createClient(request)
            successMessage = "Client created"
            await loadClients()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createInvoice(_ request: CreateInvoiceRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await api.createInvoice(request)
            successMessage = "Invoice created"
            await loadInvoices()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
