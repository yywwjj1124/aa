import SwiftUI
internal import Combine

@MainActor
final class FactoryWorkflowViewModel: ObservableObject {
    @Published private(set) var steps: [FactoryWorkflowStep]
    @Published var safetyChecks: [String: Bool]
    @Published var operationChecks: [String: Bool]
    @Published private(set) var arMarkerCount = 0
    @Published private(set) var evidenceNotes: [String] = []
    @Published private(set) var isWorkflowCompleted = false
    
    let incident: IncidentItem
    let template: FactoryWorkflowTemplate
    
    private let safetyItems = [
        "已穿戴当前工位要求的 PPE",
        "已确认能源隔离或设备安全模式",
        "已清空危险区域并通知相关人员"
    ]
    
    init(incident: IncidentItem) {
        self.incident = incident
        self.template = FactoryWorkflowTemplate.make(for: incident)
        self.steps = FactoryWorkflowTemplate.steps(for: incident)
        self.safetyChecks = Dictionary(uniqueKeysWithValues: safetyItems.map { ($0, false) })
        self.operationChecks = Dictionary(uniqueKeysWithValues: template.operationChecks.map { ($0, false) })
        restoreSnapshot()
    }
    
    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(steps.filter { $0.status == .completed }.count) / Double(steps.count)
    }
    
    var activeStep: FactoryWorkflowStep? {
        steps.first { $0.status == .active }
    }
    
    var orderedSafetyItems: [String] {
        safetyItems
    }
    
    var orderedOperationItems: [String] {
        template.operationChecks
    }
    
    var canCompleteSafety: Bool {
        safetyItems.allSatisfy { safetyChecks[$0] == true }
    }
    
    var canCompleteOperation: Bool {
        template.operationChecks.allSatisfy { operationChecks[$0] == true }
    }
    
    func setSafetyCheck(_ item: String, isOn: Bool) {
        safetyChecks[item] = isOn
        persist()
    }
    
    func setOperationCheck(_ item: String, isOn: Bool) {
        operationChecks[item] = isOn
        persist()
    }
    
    func completeSafetyGate() {
        guard activeStep?.kind == .safety, canCompleteSafety else { return }
        completeStep(kind: .safety, evidence: "安全前置条件已由现场人员确认")
    }
    
    func recordARMarkers(_ count: Int) {
        guard count > 0 else { return }
        arMarkerCount = count
        if activeStep?.kind == .spatial {
            completeStep(kind: .spatial, evidence: "RealityKit 已保存 \(count) 个空间异常标记")
        } else {
            persist()
        }
    }
    
    func completeOperation() {
        guard activeStep?.kind == .operation, canCompleteOperation else { return }
        completeStep(kind: .operation, evidence: "标准作业检查点已全部完成")
    }
    
    func buildEvidencePackage() {
        guard activeStep?.kind == .evidence else { return }
        let note = "端侧证据包：\(incident.ticketNumber) · AR \(arMarkerCount) 点 · \(Date().formatted(date: .numeric, time: .shortened))"
        completeStep(kind: .evidence, evidence: note)
    }
    
    func completeReview() {
        guard activeStep?.kind == .review else { return }
        completeStep(kind: .review, evidence: template.completionSummary)
        isWorkflowCompleted = true
        persist()
    }
    
    private func completeStep(kind: FactoryWorkflowStepKind, evidence: String) {
        guard let index = steps.firstIndex(where: { $0.kind == kind }) else { return }
        steps[index].status = .completed
        steps[index].completedAt = Date()
        evidenceNotes.append(evidence)
        
        if let nextIndex = steps.indices.first(where: { $0 > index && steps[$0].status == .pending }) {
            steps[nextIndex].status = .active
        }
        
        isWorkflowCompleted = steps.allSatisfy { $0.status == .completed }
        persist()
    }
    
    private func restoreSnapshot() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(FactoryWorkflowSnapshot.self, from: data)
        else {
            return
        }
        
        steps = snapshot.steps
        safetyChecks = snapshot.safetyChecks
        operationChecks = snapshot.operationChecks
        arMarkerCount = snapshot.arMarkerCount
        evidenceNotes = snapshot.evidenceNotes
        isWorkflowCompleted = steps.allSatisfy { $0.status == .completed }
    }
    
    private func persist() {
        let snapshot = FactoryWorkflowSnapshot(
            ticketNumber: incident.ticketNumber,
            steps: steps,
            safetyChecks: safetyChecks,
            operationChecks: operationChecks,
            arMarkerCount: arMarkerCount,
            evidenceNotes: evidenceNotes,
            updatedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private var storageKey: String {
        "voxen.factory.workflow.\(incident.ticketNumber)"
    }
}
