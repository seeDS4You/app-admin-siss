import SwiftUI

struct DocumentsView: View {
    @StateObject private var viewModel = DocumentsViewModel()
    @State private var selectedTab: DocTab = .pending
    @State private var rejectReason = ""
    @State private var selectedDoc: DocumentItem? = nil
    @State private var showRejectSheet = false

    enum DocTab: String, CaseIterable {
        case pending = "Pending"
        case all = "All"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(DocTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .pending:
                    PendingDocsList(viewModel: viewModel)
                case .all:
                    AllDocsList(viewModel: viewModel)
                }
            }
            .navigationTitle("Documents")
            .task {
                await viewModel.loadPendingDocs()
                await viewModel.loadAllDocuments()
            }
            .sheet(isPresented: $showRejectSheet) {
                NavigationView {
                    Form {
                        Section("Reason") {
                            TextField("Reason", text: $rejectReason)
                        }
                    }
                    .navigationTitle("Reject Document")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showRejectSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Reject") {
                                Task {
                                    if let doc = selectedDoc {
                                        await viewModel.rejectDocUpdate(docId: doc.id, reason: rejectReason)
                                    }
                                    showRejectSheet = false
                                }
                            }
                        }
                    }
                }
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") { viewModel.successMessage = nil }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct PendingDocsList: View {
    @ObservedObject var viewModel: DocumentsViewModel

    var body: some View {
        List {
            if viewModel.pendingDocs.isEmpty && !viewModel.isLoading {
                Text("No pending document approvals")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.pendingDocs) { user in
                    Section(header: Text(user.fullName).font(.headline)) {
                        ForEach(user.documents) { doc in
                            DocRow(doc: doc)
                                .swipeActions {
                                    Button("Approve") {
                                        Task { await viewModel.approveDocUpdate(docId: doc.id) }
                                    }
                                    .tint(.green)
                                    Button("Reject") {
                                        Task { await viewModel.rejectDocUpdate(docId: doc.id, reason: "Rejected by admin") }
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadPendingDocs()
        }
    }
}

struct AllDocsList: View {
    @ObservedObject var viewModel: DocumentsViewModel

    var body: some View {
        List {
            if viewModel.allDocuments.isEmpty && !viewModel.isLoading {
                Text("No documents found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.allDocuments) { doc in
                    DocRow(doc: doc)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadAllDocuments()
        }
    }
}

struct DocRow: View {
    let doc: DocumentItem

    var statusColor: Color {
        switch doc.status.lowercased() {
        case "approved": return .green
        case "rejected": return .red
        default: return .orange
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.docType)
                    .font(.headline)
                Text("User: \(doc.userName ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(doc.createdAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(doc.status.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}
