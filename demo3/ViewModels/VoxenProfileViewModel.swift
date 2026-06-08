import SwiftUI
internal import Combine

@MainActor
final class VoxenProfileViewModel: ObservableObject {
    // NFC 模拟交互状态机
    @Published var isNfcScanning = false
    @Published var isNfcLinked = true // 默认已绑定，展示最完美的状态
    @Published var pulseScale: CGFloat = 1.0
    @Published var selectedDialect = "粤语 (佛山顺德口音)"
    @Published var showNfcSuccessToast = false
    
    // NFC 绑定就绪微弱呼吸
    func tickNfcPulse() {
        if !isNfcScanning && !isNfcLinked {
            pulseScale = pulseScale == 1.0 ? 1.15 : 1.0
        }
    }
    
    // 模拟 NFC 物理刷卡联动行为
    func triggerNfcMock() {
        guard !isNfcScanning else { return }
        
        isNfcScanning = true
        isNfcLinked = false
        
        Task { @MainActor in
            // 1. 模拟端侧寻卡配对中...
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            withAnimation(.spring()) {
                isNfcScanning = false
                isNfcLinked = true
                showNfcSuccessToast = true
            }
            
            // 2. Toast 自动消失
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            withAnimation(.easeOut) {
                showNfcSuccessToast = false
            }
        }
    }
}
