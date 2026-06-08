import SwiftUI

struct VoxenValueDashboardView: View {
    @StateObject private var viewModel = VoxenValueDashboardViewModel()
    
    var body: some View {
        ZStack {
            T3Colors.vDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ValueDashboardHeader()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ValueMetricSummarySection()
                        DowntimeComparisonSection(downtimeData: viewModel.downtimeMock)
                        DegradationForecastSection(
                            points: viewModel.degradationMock,
                            animatePulse: viewModel.animatePulse
                        )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                viewModel.startPulseAnimation()
            }
        }
    }
}

// MARK: - SwiftUI Canvas 独立渲染预览
struct VoxenValueDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VoxenValueDashboardView()
            .preferredColorScheme(.dark)
    }
}

