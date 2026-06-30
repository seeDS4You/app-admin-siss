import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let stats = viewModel.stats {
                        statsGrid(stats: stats)
                    }

                    upcomingSection
                    messagesSection
                    attendanceSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .overlay {
                if viewModel.isLoading && viewModel.stats == nil {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func statsGrid(stats: DashboardStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Events", value: "\(stats.totalEvents)", icon: "calendar", color: .blue)
            StatCard(title: "Staff", value: "\(stats.activeStaff)", icon: "person.3", color: .green)
            StatCard(title: "Pending", value: "\(stats.pendingApprovals)", icon: "exclamationmark.triangle", color: .orange)
            StatCard(title: "Messages", value: "\(stats.unreadMessages)", icon: "envelope", color: .purple)
            StatCard(title: "Today Shifts", value: "\(stats.todayShifts)", icon: "clock", color: .cyan)
            StatCard(title: "This Week", value: "\(stats.thisWeekEvents)", icon: "calendar.badge.clock", color: .indigo)
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Events")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.upcomingEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.upcomingEvents) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Messages")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.recentMessages.isEmpty {
                Text("No recent messages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentMessages) { msg in
                    MessageRow(message: msg)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendance Summary")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.attendance.isEmpty {
                Text("No attendance data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.attendance) { day in
                    AttendanceRow(day: day)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct EventRow: View {
    let event: EventSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(event.eventDate)  \(event.startTime) - \(event.endTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let count = event.shiftCount, count > 0 {
                Text("\(count) shifts")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MessageRow: View {
    let message: MessageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.subject)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(message.body)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            Text("From: \(message.senderName)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AttendanceRow: View {
    let day: AttendanceDay

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day.date)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Present: \(day.present)  Absent: \(day.absent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(day.total)")
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
