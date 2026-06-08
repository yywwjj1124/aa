import SwiftUI
internal import Combine

@MainActor
final class VoxenValueDashboardViewModel: ObservableObject {
    // 呼吸动画开关
    @Published var animatePulse = false
    
    // 1. 重构高保真数据：本月 4 大分类异常导致的流水线累计停机损失时长对比 (Hours)
    let downtimeMock = [
        DowntimeData(category: "终端网络", processType: "传统停机损失", hours: 18.5),
        DowntimeData(category: "终端网络", processType: "Voxen 智能拦截", hours: 1.2),
        
        DowntimeData(category: "物料备料", processType: "传统停机损失", hours: 12.0),
        DowntimeData(category: "物料备料", processType: "Voxen 智能拦截", hours: 0.8),
        
        DowntimeData(category: "机台故障", processType: "传统停机损失", hours: 32.4),
        DowntimeData(category: "机台故障", processType: "Voxen 智能拦截", hours: 2.2),
        
        DowntimeData(category: "质量品控", processType: "传统停机损失", hours: 14.5),
        DowntimeData(category: "质量品控", processType: "Voxen 智能拦截", hours: 1.1)
    ]
    
    // 2. 模拟数据：当前绑定的 A-03 贴膜工位核心主轴振动劣化发展与回归预测 (周一至周日)
    let degradationMock = [
        DegradationPoint(day: "周一", index: 32.0, isPredicted: false),
        DegradationPoint(day: "周二", index: 38.0, isPredicted: false),
        DegradationPoint(day: "周三", index: 51.0, isPredicted: false),
        DegradationPoint(day: "周四", index: 65.0, isPredicted: false), // 历史真实数据到周四
        DegradationPoint(day: "周五", index: 74.0, isPredicted: true),  // 周五预测
        DegradationPoint(day: "周六", index: 88.0, isPredicted: true),  // 周六预测（开始越过 85% 物理损坏停机红线）
        DegradationPoint(day: "周日", index: 94.0, isPredicted: true)   // 周日预测
    ]
    
    func startPulseAnimation() {
        animatePulse = true
    }
}

