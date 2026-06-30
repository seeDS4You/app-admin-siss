import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    @State private var showCreateSheet = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.events.isEmpty && !viewModel.isLoading {
                    Section {
                        Text("No events found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                } else {
                    ForEach(viewModel.events) { event in
                        NavigationLink(destination: EventDetailView(eventId: event.id)) {
                            EventListRow(event: event)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let event = viewModel.events[index]
                            Task {
                                await viewModel.deleteEvent(id: event.id)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadEvents()
            }
            .task {
                await viewModel.loadEvents()
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateEventSheet(viewModel: viewModel, isPresented: $showCreateSheet)
            }
            .overlay {
                if viewModel.isLoading && viewModel.events.isEmpty {
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
}

struct EventListRow: View {
    let event: EventSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
            Text("\(event.eventDate)  \(event.startTime) - \(event.endTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let location = event.location, !location.isEmpty {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EventDetailView: View {
    let eventId: Int
    @StateObject private var viewModel = EventDetailViewModel()
    @State private var showAddShift = false
    @State private var showEditEvent = false
    @State private var selectedShift: Shift? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let event = viewModel.event {
                    eventHeader(event: event)

                    Text("Shifts")
                        .font(.headline)
                        .padding(.horizontal)

                    if event.shifts?.isEmpty ?? true {
                        Text("No shifts yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(event.shifts ?? []) { shift in
                            ShiftCard(shift: shift)
                                .onTapGesture {
                                    selectedShift = shift
                                }
                        }
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Event Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditEvent = true }) {
                    Image(systemName: "pencil")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddShift = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadEvent(id: eventId)
        }
        .sheet(isPresented: $showAddShift) {
            if let event = viewModel.event {
                AddShiftSheet(eventId: event.id, viewModel: viewModel, isPresented: $showAddShift)
            }
        }
        .sheet(isPresented: $showEditEvent) {
            if let event = viewModel.event {
                EditEventSheet(event: event, viewModel: viewModel, isPresented: $showEditEvent)
            }
        }
        .sheet(item: $selectedShift) { shift in
            EditShiftSheet(shift: shift, viewModel: viewModel, isPresented: $selectedShift)
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

    private func eventHeader(event: Event) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.title)
                .fontWeight(.bold)
            if let desc = event.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            HStack {
                Image(systemName: "calendar")
                Text(event.eventDate)
                Spacer()
                Image(systemName: "clock")
                Text("\(event.startTime) - \(event.endTime)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            if let location = event.location, !location.isEmpty {
                HStack {
                    Image(systemName: "mappin")
                    Text(location)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ShiftCard: View {
    let shift: Shift

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shift.title ?? "Shift")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(shift.startTime) - \(shift.endTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let staff = shift.staffName, !staff.isEmpty {
                    Text("Assigned: \(staff)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Unassigned")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Text("Status: \(shift.status.capitalized)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if shift.signed == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct CreateEventSheet: View {
    @ObservedObject var viewModel: EventsViewModel
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var location = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }
                Section("Date & Time") {
                    DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let dateStr = formatter.string(from: eventDate)
                            formatter.dateFormat = "HH:mm"
                            let startStr = formatter.string(from: startTime)
                            let endStr = formatter.string(from: endTime)
                            let request = CreateEventRequest(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                eventDate: dateStr,
                                startTime: startStr,
                                endTime: endStr,
                                location: location.isEmpty ? nil : location,
                                clientId: nil
                            )
                            _ = await viewModel.createEvent(request)
                            isPresented = false
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct EditEventSheet: View {
    let event: Event
    @ObservedObject var viewModel: EventDetailViewModel
    @Binding var isPresented: Bool

    @State private var title: String
    @State private var description: String
    @State private var location: String

    init(event: Event, viewModel: EventDetailViewModel, isPresented: Binding<Bool>) {
        self.event = event
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._title = State(initialValue: event.title)
        self._description = State(initialValue: event.description ?? "")
        self._location = State(initialValue: event.location ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let request = CreateEventRequest(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                eventDate: event.eventDate,
                                startTime: event.startTime,
                                endTime: event.endTime,
                                location: location.isEmpty ? nil : location,
                                clientId: event.clientId
                            )
                            await viewModel.updateEvent(id: event.id, request)
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

struct AddShiftSheet: View {
    let eventId: Int
    @ObservedObject var viewModel: EventDetailViewModel
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var description = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                Section("Time") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Shift")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            let request = CreateShiftRequest(
                                eventId: eventId,
                                title: title,
                                description: description.isEmpty ? nil : description,
                                startTime: formatter.string(from: startTime),
                                endTime: formatter.string(from: endTime)
                            )
                            await viewModel.createShift(request)
                            isPresented = false
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct EditShiftSheet: View {
    let shift: Shift
    @ObservedObject var viewModel: EventDetailViewModel
    @Binding var isPresented: Shift?

    @State private var title: String
    @State private var description: String

    init(shift: Shift, viewModel: EventDetailViewModel, isPresented: Binding<Shift?>) {
        self.shift = shift
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._title = State(initialValue: shift.title ?? "")
        self._description = State(initialValue: shift.description ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("Edit Shift")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let request = UpdateShiftRequest(
                                title: title.isEmpty ? nil : title,
                                description: description.isEmpty ? nil : description,
                                startTime: nil,
                                endTime: nil
                            )
                            await viewModel.updateShift(id: shift.id, request)
                            isPresented = nil
                        }
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.deleteShift(id: shift.id)
                            isPresented = nil
                        }
                    }
                }
            }
        }
    }
}
