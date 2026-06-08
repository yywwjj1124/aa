import SwiftUI

// MARK: - 页面路由模型
enum DashboardRoute: Hashable {
    case sandbox
}

enum ProfileRoute: Hashable {
    case secureLock
}

enum IncidentActionRoute: Hashable {
    case guidedWorkflow
    case arInspection
    case pushToTerminal
    case supervisorReview
}

// MARK: - 登录认证模式
enum VoxenLoginMode: String, CaseIterable, Identifiable {
    case employeePassword = "工号登录"
    case nfcPin = "工卡 NFC"
    
    var id: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .employeePassword:
            return "person.text.rectangle.fill"
        case .nfcPin:
            return "wave.3.right.circle.fill"
        }
    }
}

struct SandboxScenario: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let detail: String
    let colorHex: String
    let target: String
    
    var color: Color {
        Color(hex: colorHex)
    }
}

struct ArchiveEvent: Identifiable, Hashable {
    let id = UUID()
    let date: String
    let category: String
    let position: String
    let detail: String
    let status: String
    let owner: String
    let system: String
}
