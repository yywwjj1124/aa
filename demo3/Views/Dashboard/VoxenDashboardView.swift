import SwiftUI
internal import Combine

struct VoxenDashboardView: View {
    @EnvironmentObject private var agentStore: AgentIncidentStore
    @StateObject private var viewModel = VoxenDashboardViewModel()
    @StateObject private var captureViewModel = LiveAgentCaptureViewModel()
    @State private var path: [DashboardRoute] = []
    @State private var captureStartupTask: Task<Void, Never>?
    
    // 定时器：驱动视觉扫描线与声音球流体
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    // 定时器：驱动底部工单跑马灯无感流转
    let tickerTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.vBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    DashboardStatusHeader()
                    DashboardLiveCapturePanel(
                        captureViewModel: captureViewModel,
                        scanOffset: viewModel.scanOffset,
                        wavePhase: viewModel.wavePhase
                    )
                    DashboardAnalyticsSection()
                    DashboardSandboxTickerBar(
                        logMessage: viewModel.currentLogMessage,
                        tickerIndex: viewModel.tickerIndex,
                        onSandboxTap: openSandbox
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .sandbox:
                    SandboxControlCenterView()
                }
            }
            .voxenNavigationBackground(Color.vBackground)
            .voxenHideNavigationBar()
        }
        .onAppear {
            captureStartupTask?.cancel()
            captureStartupTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                captureViewModel.start(agentStore: agentStore)
            }
        }
        .onDisappear {
            captureStartupTask?.cancel()
            captureStartupTask = nil
            captureViewModel.stop()
        }
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.03)) {
                viewModel.updateScanningFrame()
            }
        }
        .onReceive(tickerTimer) { _ in
            withAnimation(.spring()) {
                viewModel.advanceTicker()
            }
        }
    }
    
    private func openSandbox() {
        viewModel.triggerSandboxMock()
        path.append(.sandbox)
    }
}

private extension View {
    @ViewBuilder
    func voxenHideNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}

// MARK: - Canvas 原生预览画布容器
struct VoxenDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VoxenDashboardView()
            .environmentObject(AgentIncidentStore())
            .preferredColorScheme(.dark)
    }
}
