import SwiftUI

struct PeopleView: View {
    @StateObject private var viewModel = PeopleViewModel()
    @State private var selectedTab: PeopleTab = .applications
    @State private var showCreateUser = false

    enum PeopleTab: String, CaseIterable {
        case applications = "Applications"
        case staff = "Staff"
        case docs = "Doc Approvals"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(PeopleTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .applications:
                    ApplicationsList(viewModel: viewModel)
                case .staff:
                    StaffList(viewModel: viewModel)
                case .docs:
                    DocApprovalsList(viewModel: viewModel)
                }
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == .staff {
                        Button(action: { showCreateUser = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadApplications()
                await viewModel.loadStaff()
                await viewModel.loadDocApprovals()
            }
            .sheet(isPresented: $showCreateUser) {
                CreateUserSheet(viewModel: viewModel, isPresented: $showCreateUser)
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

struct ApplicationsList: View {
    @ObservedObject var viewModel: PeopleViewModel
    @State private var rejectReason = ""
    @State private var selectedApp: AdminUser? = nil
    @State private var showRejectSheet = false

    var body: some View {
        List {
            if viewModel.applications.isEmpty && !viewModel.isLoading {
                Text("No pending applications")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.applications) { user in
                    ApplicationRow(user: user)
                        .swipeActions {
                            Button("Approve") {
                                Task { await viewModel.approveApplication(id: user.id) }
                            }
                            .tint(.green)
                            Button("Reject") {
                                selectedApp = user
                                showRejectSheet = true
                            }
                            .tint(.red)
                        }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadApplications()
        }
        .sheet(isPresented: $showRejectSheet) {
            NavigationView {
                Form {
                    Section("Reason") {
                        TextField("Reason", text: $rejectReason)
                    }
                }
                .navigationTitle("Reject Application")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showRejectSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Reject") {
                            Task {
                                if let user = selectedApp {
                                    await viewModel.rejectApplication(id: user.id, reason: rejectReason)
                                }
                                showRejectSheet = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ApplicationRow: View {
    let user: AdminUser

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.fullName)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(user.role.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct StaffList: View {
    @ObservedObject var viewModel: PeopleViewModel

    var body: some View {
        List {
            if viewModel.staff.isEmpty && !viewModel.isLoading {
                Text("No staff found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.staff) { user in
                    NavigationLink(destination: StaffDetailView(userId: user.id)) {
                        StaffRow(user: user)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadStaff()
        }
    }
}

struct StaffRow: View {
    let user: AdminUser

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.fullName)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(user.role.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct DocApprovalsList: View {
    @ObservedObject var viewModel: PeopleViewModel
    @State private var rejectReason = ""
    @State private var selectedUser: DocApprovalUser? = nil
    @State private var showRejectSheet = false

    var body: some View {
        List {
            if viewModel.docApprovals.isEmpty && !viewModel.isLoading {
                Text("No pending document approvals")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.docApprovals) { user in
                    DocApprovalRow(user: user)
                        .swipeActions {
                            Button("Approve") {
                                Task { await viewModel.approveDocs(userId: user.id) }
                            }
                            .tint(.green)
                            Button("Reject") {
                                selectedUser = user
                                showRejectSheet = true
                            }
                            .tint(.red)
                        }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadDocApprovals()
        }
        .sheet(isPresented: $showRejectSheet) {
            NavigationView {
                Form {
                    Section("Reason") {
                        TextField("Reason", text: $rejectReason)
                    }
                }
                .navigationTitle("Reject Documents")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showRejectSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Reject") {
                            Task {
                                if let user = selectedUser {
                                    await viewModel.rejectDocs(userId: user.id, reason: rejectReason)
                                }
                                showRejectSheet = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DocApprovalRow: View {
    let user: DocApprovalUser

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.fullName)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(user.pendingCount) pending docs")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct StaffDetailView: View {
    let userId: Int
    @StateObject private var viewModel = StaffDetailViewModel()
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let user = viewModel.user {
                    userHeader(user: user)
                    contactSection(user: user)
                    rightsSection(user: user)
                    documentsSection(user: user)
                    actionButtons(user: user)
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Staff Detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .task {
            await viewModel.loadUser(id: userId)
        }
        .sheet(isPresented: $showEditSheet) {
            if let user = viewModel.user {
                EditUserSheet(user: user, viewModel: viewModel, isPresented: $showEditSheet)
            }
        }
        .alert("Delete User?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser(id: userId)
                }
            }
        } message: {
            Text("This action cannot be undone.")
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

    private func userHeader(user: AdminUser) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(user.fullName)
                .font(.title)
                .fontWeight(.bold)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(user.role.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func contactSection(user: AdminUser) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact Info")
                .font(.headline)
            if let phone = user.contactNumber, !phone.isEmpty {
                Label(phone, systemImage: "phone")
            }
            if let address = user.address, !address.isEmpty {
                Label(address, systemImage: "house")
            }
            if let postcode = user.postcode, !postcode.isEmpty {
                Label(postcode, systemImage: "mappin")
            }
            if let dob = user.dateOfBirth, !dob.isEmpty {
                Label(dob, systemImage: "calendar")
            }
            if let ni = user.niNumber, !ni.isEmpty {
                Label(ni, systemImage: "doc.text")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func rightsSection(user: AdminUser) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rights")
                .font(.headline)
            if let rights = user.rights {
                RightsToggleRow(label: "Shifts", value: rights.shifts) { newValue in
                    var req = UpdateRightsRequest()
                    req.shifts = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "Finance", value: rights.finance) { newValue in
                    var req = UpdateRightsRequest()
                    req.finance = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "Docs", value: rights.docs) { newValue in
                    var req = UpdateRightsRequest()
                    req.docs = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "Clients", value: rights.clients) { newValue in
                    var req = UpdateRightsRequest()
                    req.clients = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "Events", value: rights.events) { newValue in
                    var req = UpdateRightsRequest()
                    req.events = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "News", value: rights.news) { newValue in
                    var req = UpdateRightsRequest()
                    req.news = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "Scan", value: rights.scan) { newValue in
                    var req = UpdateRightsRequest()
                    req.scan = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
                RightsToggleRow(label: "Admin", value: rights.admin) { newValue in
                    var req = UpdateRightsRequest()
                    req.admin = newValue
                    Task { await viewModel.updateRights(id: user.id, req) }
                }
            } else {
                Text("No rights assigned")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func documentsSection(user: AdminUser) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Documents")
                .font(.headline)
            if let docs = user.documents, !docs.isEmpty {
                ForEach(docs) { doc in
                    HStack {
                        Text(doc.docType)
                            .font(.subheadline)
                        Spacer()
                        Text(doc.status.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor(doc.status))
                            .cornerRadius(4)
                    }
                }
            } else {
                Text("No documents")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func actionButtons(user: AdminUser) -> some View {
        VStack(spacing: 12) {
            Button(action: {
                Task { await viewModel.resetPassword(id: user.id) }
            }) {
                Label("Reset Password", systemImage: "key")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: { showDeleteAlert = true }) {
                Label("Delete User", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "approved": return .green.opacity(0.2)
        case "rejected": return .red.opacity(0.2)
        default: return .orange.opacity(0.2)
        }
    }
}

struct RightsToggleRow: View {
    let label: String
    let value: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(label, isOn: .init(
            get: { value },
            set: { onChange($0) }
        ))
    }
}

struct CreateUserSheet: View {
    @ObservedObject var viewModel: PeopleViewModel
    @Binding var isPresented: Bool

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var contactNumber = ""
    @State private var role = "staff"
    @State private var address = ""
    @State private var postcode = ""
    @State private var dateOfBirth = ""
    @State private var niNumber = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                    TextField("Contact Number", text: $contactNumber)
                        .textContentType(.telephoneNumber)
                }
                Section("Role") {
                    Picker("Role", selection: $role) {
                        Text("Staff").tag("staff")
                        Text("Admin").tag("admin")
                    }
                }
                Section("Optional") {
                    TextField("Address", text: $address)
                    TextField("Postcode", text: $postcode)
                    TextField("Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                    TextField("NI Number", text: $niNumber)
                }
            }
            .navigationTitle("New User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let request = CreateUserRequest(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                password: password,
                                contactNumber: contactNumber.isEmpty ? nil : contactNumber,
                                role: role,
                                address: address.isEmpty ? nil : address,
                                postcode: postcode.isEmpty ? nil : postcode,
                                dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth,
                                niNumber: niNumber.isEmpty ? nil : niNumber
                            )
                            _ = await viewModel.createUser(request)
                            isPresented = false
                        }
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

struct EditUserSheet: View {
    let user: AdminUser
    @ObservedObject var viewModel: StaffDetailViewModel
    @Binding var isPresented: Bool

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var contactNumber: String
    @State private var address: String
    @State private var postcode: String
    @State private var dateOfBirth: String
    @State private var niNumber: String

    init(user: AdminUser, viewModel: StaffDetailViewModel, isPresented: Binding<Bool>) {
        self.user = user
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._firstName = State(initialValue: user.firstName)
        self._lastName = State(initialValue: user.lastName)
        self._email = State(initialValue: user.email)
        self._contactNumber = State(initialValue: user.contactNumber ?? "")
        self._address = State(initialValue: user.address ?? "")
        self._postcode = State(initialValue: user.postcode ?? "")
        self._dateOfBirth = State(initialValue: user.dateOfBirth ?? "")
        self._niNumber = State(initialValue: user.niNumber ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Contact Number", text: $contactNumber)
                }
                Section("Optional") {
                    TextField("Address", text: $address)
                    TextField("Postcode", text: $postcode)
                    TextField("Date of Birth (YYYY-MM-DD)", text: $dateOfBirth)
                    TextField("NI Number", text: $niNumber)
                }
            }
            .navigationTitle("Edit User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let request = UpdateUserRequest(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                contactNumber: contactNumber.isEmpty ? nil : contactNumber,
                                address: address.isEmpty ? nil : address,
                                postcode: postcode.isEmpty ? nil : postcode,
                                dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth,
                                niNumber: niNumber.isEmpty ? nil : niNumber,
                                rightToWork: nil,
                                dbs: nil,
                                dbsUpdateNo: nil,
                                companyName: nil,
                                insurance: nil
                            )
                            await viewModel.updateUser(id: user.id, request)
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
