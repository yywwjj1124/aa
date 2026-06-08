import SwiftUI

// MARK: - TAB 3 专用物理隔离调色盘 (100% 杜绝跨文件同名命名空间冲突)
struct T3Colors {
    static let vDarkBg = Color(t3Hex: "0A0E1A")       // 深夜冷科技黑蓝
    static let vSlateCard = Color(t3Hex: "161C2C")    // 高级半透明石墨灰
    static let vLaserCyan = Color(t3Hex: "00F2FE")    // 激光蓝
    static let vHealGreen = Color(t3Hex: "34C759")    // OEE 挽回绿
    static let vWarningRed = Color(t3Hex: "FF3B30")   // 停机警戒红
    static let vQcPurple = Color(t3Hex: "AF52DE")     // 质量品控紫
    static let vMutedGray = Color(t3Hex: "4A5568")    // 传统停机损失灰色
    static let vGoldYellow = Color(t3Hex: "FFCC00")   // PHM 预测金黄
}

// MARK: - 局部专用高保真模拟数据模型
struct DowntimeData: Identifiable, Equatable {
    let id = UUID()
    let category: String  // 终端网络 / 物料备料 / 机台故障 / 质量品控
    let processType: String // "传统停机损失" or "Voxen 智能拦截"
    let hours: Double     // 累计停机损失时间 (单位: 小时)
}

struct DegradationPoint: Identifiable, Equatable {
    let id = UUID()
    let day: String       // 周一至周日
    let index: Double     // 劣化度 (0 - 100)
    let isPredicted: Bool  // 是否为 CreateML 时序回归预测点
}

// MARK: - Color Hex 转换本地私有扩展
extension Color {
    init(t3Hex: String) {
        let hex = t3Hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

