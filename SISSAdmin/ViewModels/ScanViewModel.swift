import Foundation
import Combine

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var scanResult: ScanResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showResult: Bool = false

    private let api = APIClient.shared

    func scanQr(token: String) async {
        isLoading = true
        errorMessage = nil
        showResult = false
        scanResult = nil

        let result = await api.scanQr(token: token)
        switch result {
        case .success(let response):
            scanResult = response
            showResult = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reset() {
        scanResult = nil
        showResult = false
        errorMessage = nil
    }
}
