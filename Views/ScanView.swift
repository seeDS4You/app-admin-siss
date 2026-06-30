import SwiftUI
import AVFoundation

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var manualToken = ""
    @State private var showManualEntry = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if viewModel.showResult, let result = viewModel.scanResult {
                    ScanResultCard(result: result) {
                        viewModel.reset()
                    }
                } else if !showManualEntry {
                    QRScannerView { code in
                        Task {
                            await viewModel.scanQr(token: code)
                        }
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            Button(action: { showManualEntry = true }) {
                                Text("Enter Token Manually")
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.bottom, 40)
                        }
                    )
                } else {
                    manualEntryView
                }

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.5))
                }
            }
            .navigationTitle("Scan QR")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var manualEntryView: some View {
        VStack(spacing: 24) {
            Text("Enter Token")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Token", text: $manualToken)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button(action: { showManualEntry = false }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }

                Button(action: {
                    Task {
                        await viewModel.scanQr(token: manualToken)
                        showManualEntry = false
                        manualToken = ""
                    }
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(manualToken.isEmpty)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
    }
}

struct ScanResultCard: View {
    let result: ScanResponse
    let onScanNext: () -> Void

    var statusColor: Color {
        if result.success {
            if result.message?.lowercased().contains("already") == true {
                return .yellow
            }
            return .green
        }
        return .red
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(statusColor)

            Text(result.message ?? result.error ?? "Unknown result")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            if let data = result.data {
                VStack(alignment: .leading, spacing: 8) {
                    if let staff = data.staffName {
                        Label(staff, systemImage: "person")
                    }
                    if let event = data.eventTitle {
                        Label(event, systemImage: "calendar")
                    }
                    if let checkIn = data.checkIn {
                        Label("Check-in: \(checkIn)", systemImage: "clock")
                    }
                    Label("Status: \(data.status.capitalized)", systemImage: "info.circle")
                }
                .font(.subheadline)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            Button(action: onScanNext) {
                Text("Scan Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}

// MARK: - QRScanner UIViewRepresentable
struct QRScannerView: UIViewRepresentable {
    var onScan: (String) -> Void

    func makeUIView(context: Context) -> QRScannerUIView {
        let view = QRScannerUIView()
        view.onScan = onScan
        view.startScanning()
        return view
    }

    func updateUIView(_ uiView: QRScannerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: QRScannerUIView, coordinator: Coordinator) {
        uiView.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {}
}

class QRScannerUIView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.addSublayer(preview)
        previewLayer = preview

        // Add overlay corners
        let overlay = createOverlay()
        addSubview(overlay)
    }

    private func createOverlay() -> UIView {
        let view = UIView(frame: bounds)
        view.backgroundColor = .clear

        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: bounds)
        let scanBox = CGRect(
            x: bounds.width * 0.15,
            y: bounds.height * 0.3,
            width: bounds.width * 0.7,
            height: bounds.width * 0.7
        )
        path.append(UIBezierPath(rect: scanBox).reversing())
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(maskLayer)

        let border = CAShapeLayer()
        border.path = UIBezierPath(rect: scanBox).cgPath
        border.strokeColor = UIColor.white.cgColor
        border.lineWidth = 2
        border.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(border)

        return view
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func startScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned, let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let stringValue = metadataObject.stringValue else { return }
        hasScanned = true
        stopScanning()
        onScan?(stringValue)
    }

    deinit {
        stopScanning()
    }
}
