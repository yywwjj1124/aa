import SwiftUI

// MARK: - 首页无感任务流转日志模型
struct DashboardLogItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

// MARK: - 核心配色方案 (2026 苹果工业互联网调色盘)
extension Color {
    static let vBackground = Color(hex: "0A0E1A") // 深夜冷科技黑蓝
    static let vLaserBlue = Color(hex: "00F2FE")   // 空间视觉激光蓝
    static let vRpaGreen = Color(hex: "34C759")    // 流程自愈绿
    static let vWarningRed = Color(hex: "FF3B30")  // 冰山隐形瓶颈红
    static let vCardBg = Color(hex: "161C2C")      // 高级半透明石墨灰
}

// MARK: - Hex 颜色解析转换辅助器
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8 * 4) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 7: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
