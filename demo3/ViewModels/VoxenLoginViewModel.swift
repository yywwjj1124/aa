import SwiftUI
internal import Combine

@MainActor
final class VoxenLoginViewModel: ObservableObject {
    @Published var selectedMode: VoxenLoginMode = .employeePassword
    @Published var employeeId = ""
    @Published var password = ""
    @Published var pinCode = ""
    @Published var isNfcLinked = false
    @Published var isAuthenticating = false
    @Published var loginMessage = "Voxen Edge ID Ready"
    
    var canLoginWithPassword: Bool {
        employeeId.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 && password.count >= 4
    }
    
    var canLoginWithNfc: Bool {
        isNfcLinked && pinCode.count == 6
    }
    
    var canSubmit: Bool {
        switch selectedMode {
        case .employeePassword:
            return canLoginWithPassword
        case .nfcPin:
            return canLoginWithNfc
        }
    }
    
    func switchMode(_ mode: VoxenLoginMode) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedMode = mode
            loginMessage = mode == .employeePassword ? "Voxen Edge ID Ready" : "NFC Secure Channel Ready"
        }
    }
    
    func scanNfcCard() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        loginMessage = "正在读取工卡安全区"
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                isNfcLinked = true
                isAuthenticating = false
                loginMessage = "工卡已绑定 · 等待 PIN"
            }
        }
    }
    
    func submit(onAuthenticated: @escaping () -> Void) {
        guard canSubmit, !isAuthenticating else { return }
        isAuthenticating = true
        loginMessage = "正在校验身份凭证"
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 720_000_000)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                isAuthenticating = false
                loginMessage = "身份校验通过"
                onAuthenticated()
            }
        }
    }
}
