import SwiftUI

struct FactoryWorkflowExecutionView: View {
    @StateObject private var viewModel: FactoryWorkflowViewModel
    
    init(incident: IncidentItem) {
        _viewModel = StateObject(wrappedValue: FactoryWorkflowViewModel(incident: incident))
    }
    
    var body: some View {
        ZStack {
            Color(t2Hex: "101422")
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    WorkflowProgressHeader(viewModel: viewModel)
                    WorkflowStepRail(steps: viewModel.steps)
                    
                    if let activeStep = viewModel.activeStep {
                        WorkflowActiveStepPanel(viewModel: viewModel, step: activeStep)
                    } else if viewModel.isWorkflowCompleted {
                        WorkflowCompletionPanel(viewModel: viewModel)
                    }
                    
                    WorkflowEvidenceLog(notes: viewModel.evidenceNotes)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("标准作业流程")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(Color(t2Hex: "101422"))
    }
}

private struct WorkflowProgressHeader: View {
    @ObservedObject var viewModel: FactoryWorkflowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.incident.category)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(viewModel.incident.ticketNumber)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(viewModel.incident.categoryColor)
            }
            
            ProgressView(value: viewModel.progress)
                .tint(viewModel.incident.categoryColor)
            
            HStack(spacing: 8) {
                Label("端侧离线可执行", systemImage: "iphone.and.arrow.forward")
                Spacer()
                Label("步骤不可跳过", systemImage: "lock.fill")
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WorkflowStepRail: View {
    let steps: [FactoryWorkflowStep]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(stepColor(step).opacity(0.16))
                                .frame(width: 34, height: 34)
                            Image(systemName: step.status == .completed ? "checkmark" : step.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(stepColor(step))
                        }
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(step.status == .completed ? Color.t2HealGreen.opacity(0.5) : Color.white.opacity(0.08))
                                .frame(width: 2, height: 30)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(statusLabel(step))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(stepColor(step))
                    }
                    .padding(.top, 3)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func stepColor(_ step: FactoryWorkflowStep) -> Color {
        switch step.status {
        case .completed:
            return .t2HealGreen
        case .active:
            return .t2Cyan
        case .pending:
            return .white
        }
    }
    
    private func statusLabel(_ step: FactoryWorkflowStep) -> String {
        switch step.status {
        case .completed:
            return "已完成"
        case .active:
            return "当前步骤"
        case .pending:
            return "等待前序步骤"
        }
    }
}

private struct WorkflowActiveStepPanel: View {
    @ObservedObject var viewModel: FactoryWorkflowViewModel
    let step: FactoryWorkflowStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(step.title, systemImage: step.icon)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.t2Cyan)
            
            Text(step.instruction)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(4)
            
            switch step.kind {
            case .safety:
                WorkflowChecklist(
                    items: viewModel.orderedSafetyItems,
                    values: viewModel.safetyChecks,
                    onChange: viewModel.setSafetyCheck
                )
                WorkflowCommandButton(
                    title: "确认安全条件并进入现场",
                    icon: "shield.checkered",
                    enabled: viewModel.canCompleteSafety,
                    action: viewModel.completeSafetyGate
                )
                
            case .spatial:
                NavigationLink {
                    ARIncidentInspectionView(
                        incident: viewModel.incident,
                        onMarkersCommitted: viewModel.recordARMarkers
                    )
                } label: {
                    WorkflowCommandLabel(
                        title: "扫描现场并标记异常位置",
                        icon: "arkit",
                        enabled: true
                    )
                }
                
            case .operation:
                WorkflowChecklist(
                    items: viewModel.orderedOperationItems,
                    values: viewModel.operationChecks,
                    onChange: viewModel.setOperationCheck
                )
                WorkflowCommandButton(
                    title: "完成标准作业检查",
                    icon: "checklist.checked",
                    enabled: viewModel.canCompleteOperation,
                    action: viewModel.completeOperation
                )
                
            case .evidence:
                VStack(spacing: 9) {
                    WorkflowEvidenceRow(title: "原始语音译轨", value: "已保存在当前异常对象")
                    WorkflowEvidenceRow(title: "AR 空间标记", value: "\(viewModel.arMarkerCount) 个")
                    WorkflowEvidenceRow(title: "安全与作业检查", value: "已通过步骤门禁")
                }
                WorkflowCommandButton(
                    title: "生成并保存本地证据包",
                    icon: "shippingbox.fill",
                    enabled: true,
                    action: viewModel.buildEvidencePackage
                )
                
            case .review:
                WorkflowEvidenceRow(title: "目标系统", value: viewModel.incident.targetSystem)
                WorkflowEvidenceRow(title: "完工摘要", value: viewModel.template.completionSummary)
                WorkflowCommandButton(
                    title: "确认完工并进入系统回写队列",
                    icon: "checkmark.seal.fill",
                    enabled: true,
                    action: viewModel.completeReview
                )
                
            case .context:
                EmptyView()
            }
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.t2Cyan.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct WorkflowChecklist: View {
    let items: [String]
    let values: [String: Bool]
    let onChange: (String, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    onChange(item, !(values[item] ?? false))
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: values[item] == true ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(values[item] == true ? .t2HealGreen : .white)
                        Text(item)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(11)
                    .background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WorkflowCommandButton: View {
    let title: String
    let icon: String
    let enabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            WorkflowCommandLabel(title: title, icon: icon, enabled: enabled)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct WorkflowCommandLabel: View {
    let title: String
    let icon: String
    let enabled: Bool
    
    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.black.opacity(enabled ? 1 : 0.45))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: enabled
                        ? [Color.t2Cyan, Color.t2HealGreen]
                        : [Color.white.opacity(0.25), Color.white.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WorkflowEvidenceRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct WorkflowEvidenceLog: View {
    let notes: [String]
    
    var body: some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("本地审计轨迹", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                    HStack(alignment: .top, spacing: 9) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.t2Cyan)
                        Text(note)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(3)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.t2SlateCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct WorkflowCompletionPanel: View {
    @ObservedObject var viewModel: FactoryWorkflowViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.t2HealGreen)
            Text("标准作业已闭环")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(viewModel.template.completionSummary)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color.t2HealGreen.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.t2HealGreen.opacity(0.28), lineWidth: 1)
        )
    }
}
