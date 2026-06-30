import SwiftUI

@main
struct SISSAdminApp: App {
    @StateObject private var session = SessionManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await session.checkAuth()
            }
        }
    }
}

struct MainTabView: View {
    @StateObject private var session = SessionManager.shared

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            PeopleView()
                .tabItem {
                    Label("People", systemImage: "person.3")
                }

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "qrcode")
                }

            FinanceView()
                .tabItem {
                    Label("Finance", systemImage: "sterlingsign.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
