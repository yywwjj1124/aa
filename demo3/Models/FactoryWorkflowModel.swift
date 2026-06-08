import Foundation

enum FactoryWorkflowStepKind: String, Codable {
    case context
    case safety
    case spatial
    case operation
    case evidence
    case review
}

enum FactoryWorkflowStepStatus: String, Codable {
    case pending
    case active
    case completed
}

struct FactoryWorkflowStep: Identifiable, Codable, Equatable {
    let id: String
    let kind: FactoryWorkflowStepKind
    let title: String
    let instruction: String
    let icon: String
    var status: FactoryWorkflowStepStatus
    var completedAt: Date?
}

struct FactoryWorkflowSnapshot: Codable {
    let ticketNumber: String
    let steps: [FactoryWorkflowStep]
    let safetyChecks: [String: Bool]
    let operationChecks: [String: Bool]
    let arMarkerCount: Int
    let evidenceNotes: [String]
    let updatedAt: Date
}

struct FactoryWorkflowTemplate {
    let operationChecks: [String]
    let completionSummary: String
    
    static func make(for incident: IncidentItem) -> FactoryWorkflowTemplate {
        switch incident.category {
        case "电脑终端异常":
            return FactoryWorkflowTemplate(
                operationChecks: [
                    "核对终端资产编号与工位一致",
                    "保存蓝屏或驱动错误现场证据",
                    "检查扫码枪 USB 与网络链路",
                    "确认生产数据已保护后再执行重启"
                ],
                completionSummary: "终端状态、外设链路和恢复结果已形成 ITSM 证据包。"
            )
        case "物料即将耗尽":
            return FactoryWorkflowTemplate(
                operationChecks: [
                    "核对物料编码、批次与工位需求",
                    "确认现场剩余量和预计耗尽时间",
                    "检查 WMS 备库与配送容器",
                    "班长确认后放行叉车配送任务"
                ],
                completionSummary: "缺料风险、备库锁定与配送确认已形成 WMS 领料记录。"
            )
        case "机台劣化故障":
            return FactoryWorkflowTemplate(
                operationChecks: [
                    "确认设备已停机或进入安全维护模式",
                    "记录气压、温度、振动或异响位置",
                    "检查防护罩、能源隔离与工具状态",
                    "试运行后确认风险指标恢复正常"
                ],
                completionSummary: "故障位置、维修动作与试运行结果已形成 EAM 维护记录。"
            )
        default:
            return FactoryWorkflowTemplate(
                operationChecks: [
                    "核对产品型号、批次与检验标准",
                    "使用 AR 标记气泡、划痕或裂纹区域",
                    "抽检相邻产品并确认是否为批次问题",
                    "确认隔离数量与 MES 批次状态"
                ],
                completionSummary: "缺陷位置、抽检结果与批次处置已形成 MES/QC 证据包。"
            )
        }
    }
    
    static func steps(for incident: IncidentItem) -> [FactoryWorkflowStep] {
        [
            FactoryWorkflowStep(
                id: "context",
                kind: .context,
                title: "工单与工位绑定",
                instruction: "核对工单、设备/批次、工位和当前操作人员，避免处置对象错误。",
                icon: "link.badge.plus",
                status: .completed,
                completedAt: Date()
            ),
            FactoryWorkflowStep(
                id: "safety",
                kind: .safety,
                title: "安全前置确认",
                instruction: "完成 PPE、能源隔离和作业区域确认后，才能进入现场操作。",
                icon: "shield.checkered",
                status: .active,
                completedAt: nil
            ),
            FactoryWorkflowStep(
                id: "spatial",
                kind: .spatial,
                title: "AR 空间定位",
                instruction: "将异常点锚定到真实设备或产品表面，形成可复现的位置证据。",
                icon: "arkit",
                status: .pending,
                completedAt: nil
            ),
            FactoryWorkflowStep(
                id: "operation",
                kind: .operation,
                title: "执行标准作业",
                instruction: "按当前异常类型逐项完成检查和处置，禁止跳过关键步骤。",
                icon: "checklist.checked",
                status: .pending,
                completedAt: nil
            ),
            FactoryWorkflowStep(
                id: "evidence",
                kind: .evidence,
                title: "生成端侧证据包",
                instruction: "在本机汇总时间、人员、译轨、AR 标记与检查结果，断网也可保存。",
                icon: "shippingbox.and.arrow.backward.fill",
                status: .pending,
                completedAt: nil
            ),
            FactoryWorkflowStep(
                id: "review",
                kind: .review,
                title: "完工复核与回写",
                instruction: "由责任人确认结果，再同步到 ITSM、WMS、EAM 或 MES。",
                icon: "checkmark.seal.fill",
                status: .pending,
                completedAt: nil
            )
        ]
    }
}
