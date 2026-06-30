import Foundation
import Combine

@MainActor
final class EventDetailViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIClient.shared

    func loadEvent(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            event = try await api.getEvent(id: id)
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateEvent(id: Int, _ request: CreateEventRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            event = try await api.updateEvent(id: id, request)
            successMessage = "Event updated"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createShift(_ request: CreateShiftRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await api.createShift(request)
            successMessage = "Shift created"
            if let eventId = event?.id {
                await loadEvent(id: eventId)
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateShift(id: Int, _ request: UpdateShiftRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await api.updateShift(id: id, request)
            successMessage = "Shift updated"
            if let eventId = event?.id {
                await loadEvent(id: eventId)
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteShift(id: Int) async {
        isLoading = true
        do {
            try await api.deleteShift(id: id)
            successMessage = "Shift deleted"
            if let eventId = event?.id {
                await loadEvent(id: eventId)
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func allocateShift(shiftId: Int, userId: Int) async {
        isLoading = true
        do {
            let resp = try await api.allocateShift(shiftId: shiftId, userId: userId)
            successMessage = resp.message ?? "Allocated"
            if let eventId = event?.id {
                await loadEvent(id: eventId)
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func cancelShift(shiftId: Int) async {
        isLoading = true
        do {
            let resp = try await api.cancelShift(shiftId: shiftId)
            successMessage = resp.message ?? "Cancelled"
            if let eventId = event?.id {
                await loadEvent(id: eventId)
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
