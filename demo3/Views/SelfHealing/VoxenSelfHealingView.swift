import SwiftUI
internal import Combine

struct VoxenSelfHealingView: View {
    @EnvironmentObject private var agentStore: AgentIncidentStore
    @StateObject private var viewModel = VoxenSelfHealingViewModel()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.t2DarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                SelfHealingHeader(pulseWave: viewModel.pulseWave)
                
                IncidentSearchBar(
                    searchText: $viewModel.searchText,
                    onClear: viewModel.clearSearch
                )
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        IncidentQueueSection(
                            incidents: viewModel.filteredIncidents(liveIncidents: agentStore.publishedIncidents),
                            onSelect: viewModel.selectIncident
                        )
                        
                        IncidentHistoryArchiveEntry(
                            onTap: viewModel.showHistoryArchive
                        )
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                viewModel.tickPulse()
            }
        }
        .sheet(item: $viewModel.activeSheetIncident) { incident in
            IncidentDetailSheetView(incident: incident)
        }
        .sheet(isPresented: $viewModel.isShowingHistorySheet) {
            T2HistoryArchiveSheetView()
        }
    }
}

// MARK: - SwiftUI Canvas 独立渲染预览
struct VoxenSelfHealingView_Previews: PreviewProvider {
    static var previews: some View {
        VoxenSelfHealingView()
            .environmentObject(AgentIncidentStore())
            .preferredColorScheme(.dark)
    }
}
