import SwiftUI
internal import Combine

@MainActor
final class VoxenDashboardViewModel: ObservableObject {
    // 动画状态机控制
    @Published var wavePhase: Double = 0.0
    @Published var scanOffset: CGFloat = -110
    @Published var isScanningForward = true
    @Published var tickerIndex = 0
    
    let mockLogs = [
        DashboardLogItem(message: "[10分钟前] A-03贴膜机吸盘磨损工单，RPA已自动生成通知并分发..."),
        DashboardLogItem(message: "[45分钟前] B-12仓位螺丝物料见底，Agent自动触发上游多方询价..."),
        DashboardLogItem(message: "[2小时前] 进货单据与WMS数据冲突，Live Text端侧无感审计冲账成功...")
    ]
    
    var currentLogMessage: String {
        mockLogs[tickerIndex].message
    }
    
    // 驱动声音球相位与激光线循环偏移动画
    func updateScanningFrame() {
        wavePhase += 0.15
        
        if isScanningForward {
            scanOffset += 2.5
            if scanOffset >= 110 { isScanningForward = false }
        } else {
            scanOffset -= 2.5
            if scanOffset <= -110 { isScanningForward = true }
        }
    }
    
    // 自动循环流转更新工单状态数据
    func advanceTicker() {
        tickerIndex = (tickerIndex + 1) % mockLogs.count
    }
    
    // 预留触发沙盒数据注入动作的动作区
    func triggerSandboxMock() {
    }
}

