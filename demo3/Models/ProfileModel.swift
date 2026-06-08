import SwiftUI

// MARK: - TAB 4 专用物理隔离调色盘 (彻底断绝多文件全局同名重声明冲突)
struct T4Colors {
    static let vDarkBg = Color(t4Hex: "0A0E1A")       // 深夜冷科技黑蓝
    static let vSlateCard = Color(t4Hex: "161C2C")    // 高级半透明石墨灰
    static let vLaserCyan = Color(t4Hex: "00F2FE")    // 激光蓝
    static let vHealGreen = Color(t4Hex: "34C759")    // 流程通过绿
    static let vWarningRed = Color(t4Hex: "FF3B30")   // 退出/注销红色
    static let vOrangeAlert = Color(t4Hex: "FF9500")  // 智能警告橙
    static let vDialectPurple = Color(t4Hex: "AF52DE") // 方言深紫
}

// MARK: - Color Hex 转换本地私有扩展
extension Color {
    init(t4Hex: String) {
        let hex = t4Hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

