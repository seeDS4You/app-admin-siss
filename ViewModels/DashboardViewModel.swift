import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var upcomingEvents: [EventSummary] = []
    @Published var recentMessages: [MessageSummary] = []
    @Published var attendance: [AttendanceDay] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api = APIClient.shared

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await api.getDashboard()
            stats = data.stats
            upcomingEvents = data.upcomingEvents
            recentMessages = data.recentMessages
            attendance = data.attendance
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
