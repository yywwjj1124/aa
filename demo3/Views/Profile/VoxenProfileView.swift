import SwiftUI
internal import Combine

struct VoxenProfileView: View {
    @StateObject private var viewModel = VoxenProfileViewModel()
    @State private var path: [ProfileRoute] = []
    
    // 定时器用于驱动 NFC 呼吸涟漪
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                T4Colors.vDarkBg
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ProfileWorkerCard(selectedDialect: $viewModel.selectedDialect)
                        
                        WorkstationBindingCard(
                            isNfcScanning: viewModel.isNfcScanning,
                            isNfcLinked: viewModel.isNfcLinked,
                            onNfcTap: viewModel.triggerNfcMock
                        )
                        
                        DeviceSecuritySection()
                        Spacer(minLength: 24)
                        ProfileLogoutButton(onTap: openSecureLock)
                    }
                }
                
                if viewModel.showNfcSuccessToast {
                    NfcSuccessToast()
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .secureLock:
                    SecureLockScreenView()
                }
            }
            .voxenNavigationBackground(T4Colors.vDarkBg)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                viewModel.tickNfcPulse()
            }
        }
    }
    
    private func openSecureLock() {
        path.append(.secureLock)
    }
}

// MARK: - SwiftUI Canvas 独立渲染预览
struct VoxenProfileView_Previews: PreviewProvider {
    static var previews: some View {
        VoxenProfileView()
            .preferredColorScheme(.dark)
    }
}
