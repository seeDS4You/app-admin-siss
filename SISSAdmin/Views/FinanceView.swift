import SwiftUI

struct FinanceView: View {
    @StateObject private var viewModel = FinanceViewModel()
    @State private var selectedTab: FinanceTab = .clients
    @State private var showAddClient = false
    @State private var showAddInvoice = false

    enum FinanceTab: String, CaseIterable {
        case clients = "Clients"
        case invoices = "Invoices"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(FinanceTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .clients:
                    ClientsList(viewModel: viewModel)
                case .invoices:
                    InvoicesList(viewModel: viewModel)
                }
            }
            .navigationTitle("Finance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if selectedTab == .clients {
                            showAddClient = true
                        } else {
                            showAddInvoice = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadClients()
                await viewModel.loadInvoices()
            }
            .sheet(isPresented: $showAddClient) {
                AddClientSheet(viewModel: viewModel, isPresented: $showAddClient)
            }
            .sheet(isPresented: $showAddInvoice) {
                AddInvoiceSheet(viewModel: viewModel, isPresented: $showAddInvoice)
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

struct ClientsList: View {
    @ObservedObject var viewModel: FinanceViewModel

    var body: some View {
        List {
            if viewModel.clients.isEmpty && !viewModel.isLoading {
                Text("No clients found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.clients) { client in
                    ClientRow(client: client)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadClients()
        }
    }
}

struct ClientRow: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.name)
                .font(.headline)
            if let contact = client.contactName, !contact.isEmpty {
                Text(contact)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let email = client.contactEmail, !email.isEmpty {
                Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let phone = client.contactPhone, !phone.isEmpty {
                Text(phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InvoicesList: View {
    @ObservedObject var viewModel: FinanceViewModel

    var body: some View {
        List {
            if viewModel.invoices.isEmpty && !viewModel.isLoading {
                Text("No invoices found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.invoices) { invoice in
                    InvoiceRow(invoice: invoice)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadInvoices()
        }
    }
}

struct InvoiceRow: View {
    let invoice: Invoice

    var statusColor: Color {
        switch invoice.status.lowercased() {
        case "paid": return .green
        case "overdue": return .red
        case "pending": return .orange
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.client?.name ?? "Unknown Client")
                    .font(.headline)
                Text("£\(String(format: "%.2f", invoice.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let due = invoice.dueDate {
                    Text("Due: \(due)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(invoice.status.capitalized)
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

struct AddClientSheet: View {
    @ObservedObject var viewModel: FinanceViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var address = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Client Name", text: $name)
                    TextField("Contact Name", text: $contactName)
                    TextField("Contact Email", text: $contactEmail)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Contact Phone", text: $contactPhone)
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("New Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let request = CreateClientRequest(
                                name: name,
                                contactName: contactName.isEmpty ? nil : contactName,
                                contactEmail: contactEmail.isEmpty ? nil : contactEmail,
                                contactPhone: contactPhone.isEmpty ? nil : contactPhone,
                                address: address.isEmpty ? nil : address
                            )
                            await viewModel.createClient(request)
                            isPresented = false
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct AddInvoiceSheet: View {
    @ObservedObject var viewModel: FinanceViewModel
    @Binding var isPresented: Bool

    @State private var clientId = ""
    @State private var amount = ""
    @State private var dueDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Client ID", text: $clientId)
                        .keyboardType(.numberPad)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            guard let cid = Int(clientId), let amt = Double(amount) else { return }
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let request = CreateInvoiceRequest(
                                clientId: cid,
                                amount: amt,
                                dueDate: formatter.string(from: dueDate)
                            )
                            await viewModel.createInvoice(request)
                            isPresented = false
                        }
                    }
                    .disabled(clientId.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}
