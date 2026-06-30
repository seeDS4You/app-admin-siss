import Foundation

// MARK: - Admin User
struct AdminUser: Codable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let contactNumber: String?
    let address: String?
    let postcode: String?
    let dateOfBirth: String?
    let niNumber: String?
    let rightToWork: Bool?
    let dbs: Bool?
    let dbsUpdateNo: String?
    let companyName: String?
    let insurance: Bool?
    let role: String
    let documents: [DocumentItem]?
    var rights: UserRights?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case contactNumber = "contact_number"
        case address
        case postcode
        case dateOfBirth = "date_of_birth"
        case niNumber = "ni_number"
        case rightToWork = "right_to_work"
        case dbs
        case dbsUpdateNo = "dbs_update_no"
        case companyName = "company_name"
        case insurance
        case role
        case documents
        case rights
        case createdAt = "created_at"
    }

    var fullName: String { "\(firstName) \(lastName)" }
}

struct UserRights: Codable {
    let id: Int
    let userId: Int
    var shifts: Bool
    var finance: Bool
    var docs: Bool
    var clients: Bool
    var events: Bool
    var news: Bool
    var scan: Bool
    var admin: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shifts
        case finance
        case docs
        case clients
        case events
        case news
        case scan
        case admin
    }
}

// MARK: - Dashboard
struct DashboardStats: Codable {
    let totalEvents: Int
    let activeStaff: Int
    let pendingApprovals: Int
    let unreadMessages: Int
    let todayShifts: Int
    let thisWeekEvents: Int

    enum CodingKeys: String, CodingKey {
        case totalEvents = "total_events"
        case activeStaff = "active_staff"
        case pendingApprovals = "pending_approvals"
        case unreadMessages = "unread_messages"
        case todayShifts = "today_shifts"
        case thisWeekEvents = "this_week_events"
    }
}

struct DashboardData: Codable {
    let stats: DashboardStats
    let upcomingEvents: [EventSummary]
    let recentMessages: [MessageSummary]
    let attendance: [AttendanceDay]

    enum CodingKeys: String, CodingKey {
        case stats
        case upcomingEvents = "upcoming_events"
        case recentMessages = "recent_messages"
        case attendance
    }
}

// MARK: - Event
struct Event: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let eventDate: String
    let startTime: String
    let endTime: String
    let location: String?
    let clientId: Int?
    let createdBy: Int?
    let createdAt: String?
    let shifts: [Shift]?
    let client: Client?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case location
        case clientId = "client_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case shifts
        case client
    }
}

struct EventSummary: Codable, Identifiable {
    let id: Int
    let title: String
    let eventDate: String
    let startTime: String
    let endTime: String
    let location: String?
    let shiftCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case location
        case shiftCount = "shift_count"
    }
}

struct EventsResponse: Codable {
    let success: Bool
    let data: [EventSummary]
}

struct EventResponse: Codable {
    let success: Bool
    let data: Event
}

// MARK: - Shift
struct Shift: Codable, Identifiable {
    let id: Int
    let eventId: Int
    let userId: Int?
    let title: String?
    let description: String?
    let startTime: String
    let endTime: String
    let status: String
    let staffName: String?
    let email: String?
    let checkIn: String?
    let checkOut: String?
    let signed: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case title
        case description
        case startTime = "start_time"
        case endTime = "end_time"
        case status
        case staffName = "staff_name"
        case email
        case checkIn = "check_in"
        case checkOut = "check_out"
        case signed
    }
}

struct CreateShiftRequest: Codable {
    let eventId: Int
    let title: String
    let description: String?
    let startTime: String
    let endTime: String

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case title
        case description
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct UpdateShiftRequest: Codable {
    let title: String?
    let description: String?
    let startTime: String?
    let endTime: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

// MARK: - Message
struct MessageSummary: Codable, Identifiable {
    let id: Int
    let subject: String
    let body: String
    let senderName: String
    let createdAt: String
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case subject
        case body
        case senderName = "sender_name"
        case createdAt = "created_at"
        case isRead = "is_read"
    }
}

// MARK: - Attendance
struct AttendanceDay: Codable, Identifiable {
    let id: String
    let date: String
    let present: Int
    let absent: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case present
        case absent
        case total
    }
}

// MARK: - Client
struct Client: Codable, Identifiable {
    let id: Int
    let name: String
    let contactName: String?
    let contactEmail: String?
    let contactPhone: String?
    let address: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contactName = "contact_name"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case address
        case createdAt = "created_at"
    }
}

struct ClientsResponse: Codable {
    let success: Bool
    let data: [Client]
}

struct InvoicesResponse: Codable {
    let success: Bool
    let data: [Invoice]
}

struct CreateClientRequest: Codable {
    let name: String
    let contactName: String?
    let contactEmail: String?
    let contactPhone: String?
    let address: String?

    enum CodingKeys: String, CodingKey {
        case name
        case contactName = "contact_name"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case address
    }
}

// MARK: - Invoice
struct Invoice: Codable, Identifiable {
    let id: Int
    let clientId: Int
    let amount: Double
    let status: String
    let dueDate: String?
    let createdAt: String?
    let client: Client?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case amount
        case status
        case dueDate = "due_date"
        case createdAt = "created_at"
        case client
    }
}

struct CreateInvoiceRequest: Codable {
    let clientId: Int
    let amount: Double
    let dueDate: String?

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case amount
        case dueDate = "due_date"
    }
}

// MARK: - Document
struct DocumentItem: Codable, Identifiable {
    let id: Int
    let userId: Int
    let docType: String
    let docPath: String
    let status: String
    let createdAt: String
    let updatedAt: String?
    let userName: String?
    let adminNote: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case docType = "doc_type"
        case docPath = "doc_path"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userName = "user_name"
        case adminNote = "admin_note"
    }
}

struct DocumentsResponse: Codable {
    let success: Bool
    let data: [DocumentItem]
}

struct DocApprovalUser: Codable, Identifiable {
    let id: Int
    let fullName: String
    let email: String
    let pendingCount: Int
    let documents: [DocumentItem]

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case pendingCount = "pending_count"
        case documents
    }
}

struct DocApprovalResponse: Codable {
    let success: Bool
    let data: [DocApprovalUser]
}

// MARK: - Scan
struct ScanData: Codable {
    let id: Int
    let shiftId: Int
    let userId: Int
    let status: String
    let checkIn: String?
    let checkOut: String?
    let staffName: String?
    let eventTitle: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case id
        case shiftId = "shift_id"
        case userId = "user_id"
        case status
        case checkIn = "check_in"
        case checkOut = "check_out"
        case staffName = "staff_name"
        case eventTitle = "event_title"
        case message
    }
}

struct ScanResponse: Codable {
    let success: Bool
    let message: String?
    let data: ScanData?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case error
    }
}

// MARK: - Generic Response
struct GenericResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
    }
}

// MARK: - Create/Update Requests
struct CreateEventRequest: Codable {
    let title: String
    let description: String?
    let eventDate: String
    let startTime: String
    let endTime: String
    let location: String?
    let clientId: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case location
        case clientId = "client_id"
    }
}

struct CreateUserRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let contactNumber: String?
    let role: String
    let address: String?
    let postcode: String?
    let dateOfBirth: String?
    let niNumber: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case password
        case contactNumber = "contact_number"
        case role
        case address
        case postcode
        case dateOfBirth = "date_of_birth"
        case niNumber = "ni_number"
    }
}

struct UpdateUserRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let contactNumber: String?
    let address: String?
    let postcode: String?
    let dateOfBirth: String?
    let niNumber: String?
    let rightToWork: Bool?
    let dbs: Bool?
    let dbsUpdateNo: String?
    let companyName: String?
    let insurance: Bool?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case contactNumber = "contact_number"
        case address
        case postcode
        case dateOfBirth = "date_of_birth"
        case niNumber = "ni_number"
        case rightToWork = "right_to_work"
        case dbs
        case dbsUpdateNo = "dbs_update_no"
        case companyName = "company_name"
        case insurance
    }
}

struct UpdateRightsRequest: Codable {
    let shifts: Bool?
    let finance: Bool?
    let docs: Bool?
    let clients: Bool?
    let events: Bool?
    let news: Bool?
    let scan: Bool?
    let admin: Bool?

    enum CodingKeys: String, CodingKey {
        case shifts
        case finance
        case docs
        case clients
        case events
        case news
        case scan
        case admin
    }
}

struct RejectRequest: Codable {
    let reason: String

    enum CodingKeys: String, CodingKey {
        case reason
    }
}

// MARK: - Staff List
struct StaffListResponse: Codable {
    let success: Bool
    let data: [AdminUser]
}

// MARK: - Timesheet
struct TimesheetEntry: Codable, Identifiable {
    let id: Int
    let userId: Int
    let shiftId: Int
    let checkIn: String
    let checkOut: String?
    let hoursWorked: Double?
    let staffName: String?
    let eventTitle: String?
    let eventDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shiftId = "shift_id"
        case checkIn = "check_in"
        case checkOut = "check_out"
        case hoursWorked = "hours_worked"
        case staffName = "staff_name"
        case eventTitle = "event_title"
        case eventDate = "event_date"
    }
}

struct TimesheetResponse: Codable {
    let success: Bool
    let data: [TimesheetEntry]
}
