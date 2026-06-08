import SwiftUI

struct IncidentActionFlowView: View {
    let incident: IncidentItem
    
    var body: some View {
        ZStack {
            Color(t2Hex: "101422")
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ActionFlowHeroCard(incident: incident)
                    ActionFlowTelemetryPanel(incident: incident)
                    ActionFlowTimeline(incident: incident)
                    ActionFlowControlBar(incident: incident)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("下一步处置")
        .voxenInlineNavigationTitle()
        .navigationDestination(for: IncidentActionRoute.self) { route in
            switch route {
            case .guidedWorkflow:
                FactoryWorkflowExecutionView(incident: incident)
            case .arInspection:
                ARIncidentInspectionView(incident: incident)
            case .pushToTerminal, .supervisorReview:
                IncidentActionResultView(incident: incident, route: route)
            }
        }
        .voxenNavigationBackground(Color(t2Hex: "101422"))
    }
}

private struct ActionFlowHeroCard: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(incident.categoryColor.opacity(0.14))
                        .frame(width: 54, height: 54)
                    Image(systemName: incident.flowNodeIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(incident.categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.flowNodeTitle)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(incident.ticketNumber)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            Text(actionSummary)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private var actionSummary: String {
        switch incident.category {
        case "电脑终端异常":
            return "已锁定 B-04 包装工位终端与扫码枪链路，正在生成 AR 网络拓扑与 USB 驱动排障指引。"
        case "物料即将耗尽":
            return "已展示 WMS 备库锁料路径，等待班长刷卡确认后进入叉车配送队列。"
        case "机台劣化故障":
            return "正在拉起远程空间维修会诊，机修班长可查看主轴气压与异响定位。"
        default:
            return "正在调取端侧 Vision 瑕疵 ROI，QC 可直接查看气泡区域与批次拦截状态。"
        }
    }
}

private struct ActionFlowTelemetryPanel: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(spacing: 10) {
            VoxenInfoRow(icon: "mappin.and.ellipse", title: "工位", value: incident.location, color: incident.categoryColor)
            VoxenInfoRow(icon: "server.rack", title: "目标系统", value: incident.targetSystem, color: .t2Cyan)
            VoxenInfoRow(icon: "person.crop.circle", title: "责任人", value: incident.initiator, color: .t2HealGreen)
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ActionFlowTimeline: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("现场执行链路")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VoxenFlowStepRow(index: "01", title: "空间定位", detail: "读取工位 NFC 与端侧 Vision 坐标，把异常锚定到可抵达的物理位置。", color: incident.categoryColor)
            VoxenFlowStepRow(index: "02", title: "系统写入", detail: "将译轨、位置、风险等级、截图/日志包写入目标系统草稿单。", color: .t2Cyan)
            VoxenFlowStepRow(index: "03", title: "人工确认", detail: "保留班长或主管刷卡确认节点，满足财务、安规和质量审计。", color: .t2HealGreen)
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ActionFlowControlBar: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(spacing: 10) {
            NavigationLink(value: IncidentActionRoute.guidedWorkflow) {
                Label("开始标准作业流程", systemImage: "checklist.checked")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.t2Cyan, Color.t2HealGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
            }
            
            NavigationLink(value: IncidentActionRoute.arInspection) {
                Label("打开 AR 现场空间标注", systemImage: "arkit")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [incident.categoryColor, Color.t2Cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
            }
            
            NavigationLink(value: IncidentActionRoute.pushToTerminal) {
                Label("确认并推送到现场终端", systemImage: "paperplane.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LinearGradient(colors: [Color.t2Cyan, Color.t2HealGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(14)
            }
            
            NavigationLink(value: IncidentActionRoute.supervisorReview) {
                Label("转人工主管复核", systemImage: "person.text.rectangle.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.t2SlateCard)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(incident.categoryColor.opacity(0.25), lineWidth: 1)
                    )
            }
        }
    }
}

private struct IncidentActionResultView: View {
    let incident: IncidentItem
    let route: IncidentActionRoute
    
    var body: some View {
        ZStack {
            Color(t2Hex: "101422")
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(resultColor.opacity(0.12))
                        .frame(width: 104, height: 104)
                    Image(systemName: resultIcon)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(resultColor)
                }
                
                VStack(spacing: 6) {
                    Text(resultTitle)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(resultDetail)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                
                VStack(spacing: 10) {
                    VoxenInfoRow(icon: incident.categoryIcon, title: "异常类型", value: incident.category, color: incident.categoryColor)
                    VoxenInfoRow(icon: "number", title: "单号", value: incident.ticketNumber, color: .t2Cyan)
                    VoxenInfoRow(icon: "server.rack", title: "系统", value: incident.targetSystem, color: .t2HealGreen)
                }
                .padding(16)
                .background(Color.t2SlateCard)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
        .navigationTitle("处置结果")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(Color(t2Hex: "101422"))
    }
    
    private var resultTitle: String {
        switch route {
        case .guidedWorkflow:
            return "标准作业流程"
        case .arInspection:
            return "AR 空间标注"
        case .pushToTerminal:
            return "已推送到现场终端"
        case .supervisorReview:
            return "已转主管复核"
        }
    }
    
    private var resultDetail: String {
        switch route {
        case .guidedWorkflow:
            return "该异常已进入端侧标准作业流程。"
        case .arInspection:
            return "异常位置已通过 RealityKit 锚定到真实空间。"
        case .pushToTerminal:
            return "现场终端会收到空间定位、处置步骤与工单摘要，等待责任人刷卡确认。"
        case .supervisorReview:
            return "该异常已进入班长/主管复核队列，Agent 保留原始译轨与目标系统草稿单。"
        }
    }
    
    private var resultIcon: String {
        switch route {
        case .guidedWorkflow:
            return "checklist.checked"
        case .arInspection:
            return "arkit"
        case .pushToTerminal:
            return "paperplane.fill"
        case .supervisorReview:
            return "person.text.rectangle.fill"
        }
    }
    
    private var resultColor: Color {
        switch route {
        case .guidedWorkflow:
            return .t2Cyan
        case .arInspection:
            return .t2Cyan
        case .pushToTerminal:
            return .t2HealGreen
        case .supervisorReview:
            return incident.categoryColor
        }
    }
}
