import SwiftUI

// MARK: - TAB 2 专用物理隔离调色盘 (彻底断绝全局同名重声明冲突)
extension Color {
    static let t2DarkBg = Color(t2Hex: "0A0E1A")     // 深夜冷科技黑蓝
    static let t2Cyan = Color(t2Hex: "00F2FE")       // 激光蓝
    static let t2SlateCard = Color(t2Hex: "161C2C")  // 石墨灰半透明卡片
    static let t2HealGreen = Color(t2Hex: "34C759")  // 流程通过绿
    static let t2WarnOrange = Color(t2Hex: "FF9500") // 锁料警告橙
    static let t2WarnRed = Color(t2Hex: "FF3B30")    // 紧急呼叫红
    static let t2QcPurple = Color(t2Hex: "AF52DE")   // 品控异常紫
}

// MARK: - 工业状态卡片数据结构 (全剧本升级)
struct IncidentItem: Identifiable, Equatable {
    let id = UUID()
    let category: String       // 异常分类
    let categoryIcon: String   // 对应 SF Symbol
    let categoryColor: Color   // 分类代表色
    let originalDialect: String // 方言原轨
    let translatedText: String  // 端侧 SLM 直译
    let location: String       // 物理位置
    let initiator: String      // 发起人
    let targetSystem: String   // Agent 派发流转目的地
    let ticketNumber: String   // 系统自动生成的单号
    let details: String        // 详细派发动作动作描述
    let flowNodeTitle: String  // 演示专用主按钮动作提示
    let flowNodeIcon: String   // 主按钮图标
    
    static func == (lhs: IncidentItem, rhs: IncidentItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Color Hex 转换本地安全扩展 (与 TAB 1 彻底隔离)
extension Color {
    init(t2Hex: String) {
        let hex = t2Hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

