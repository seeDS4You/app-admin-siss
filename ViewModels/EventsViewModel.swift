import Foundation
import Combine

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [EventSummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api = APIClient.shared

    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            events = try await api.getEvents()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createEvent(_ request: CreateEventRequest) async -> Event? {
        isLoading = true
        errorMessage = nil
        do {
            let event = try await api.createEvent(request)
            await loadEvents()
            return event
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        return nil
    }

    func deleteEvent(id: Int) async {
        isLoading = true
        do {
            try await api.deleteEvent(id: id)
            await loadEvents()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
