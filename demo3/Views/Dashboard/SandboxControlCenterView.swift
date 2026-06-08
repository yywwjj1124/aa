import SwiftUI

struct SandboxControlCenterView: View {
    var body: some View {
        ZStack {
            Color.vBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    SandboxHeader()
                    SandboxScenarioGrid()
                    SandboxInjectionTimeline()
                    SandboxControlPanel()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("演示沙盒")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(Color.vBackground)
    }
}

private struct SandboxHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Voxen Demo Sandbox")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("一键注入端侧语音、视觉、工位与工单数据流")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "terminal.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.vLaserBlue)
            }
            
            HStack(spacing: 8) {
                SandboxStatusPill(title: "Local SLM", value: "Ready", color: .vRpaGreen)
                SandboxStatusPill(title: "Vision ROI", value: "Armed", color: .vLaserBlue)
                SandboxStatusPill(title: "WMS/MES", value: "Mock", color: .vWarningRed)
            }
        }
        .padding(16)
        .background(Color.vCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SandboxScenarioGrid: View {
    private let scenarios = [
        SandboxScenario(title: "电脑终端异常", icon: "laptopcomputer", detail: "注入蓝屏 + USB 驱动假死", colorHex: "0A84FF", target: "ITSM"),
        SandboxScenario(title: "物料即将耗尽", icon: "shippingbox.fill", detail: "注入低水位物料申请", colorHex: "FF9500", target: "WMS"),
        SandboxScenario(title: "机台劣化故障", icon: "gearshape.2.fill", detail: "注入气压骤降 + 异响", colorHex: "FF3B30", target: "EAM"),
        SandboxScenario(title: "产品外观不良", icon: "checkmark.seal.fill", detail: "注入 Vision 气泡 ROI", colorHex: "AF52DE", target: "MES")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可注入剧本")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(scenarios) { scenario in
                    NavigationLink(value: scenario) {
                        SandboxScenarioCard(scenario: scenario)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationDestination(for: SandboxScenario.self) { scenario in
            SandboxScenarioDetailView(scenario: scenario)
        }
    }
}

private struct SandboxInjectionTimeline: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("注入后链路")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VoxenFlowStepRow(index: "01", title: "端侧采集", detail: "模拟语音方言、摄像头 ROI 与工位 NFC 标签同时进入本地队列。", color: .vLaserBlue)
            VoxenFlowStepRow(index: "02", title: "SLM 语义规整", detail: "把大白话提报转换为标准异常类型、工位、风险等级与目标系统。", color: .vRpaGreen)
            VoxenFlowStepRow(index: "03", title: "Agent 派发", detail: "生成 ITSM / WMS / EAM / MES 对应草稿工单，保留审计链。", color: .vWarningRed)
        }
        .padding(16)
        .background(Color.vCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SandboxControlPanel: View {
    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                SandboxScenarioDetailView(
                    scenario: SandboxScenario(
                        title: "完整演示流",
                        icon: "play.fill",
                        detail: "连续注入四类异常剧本，展示端侧捕获、SLM 规整、Agent 派发和闭环审计。",
                        colorHex: "00F2FE",
                        target: "ALL"
                    )
                )
            } label: {
                Label("注入完整演示流", systemImage: "play.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LinearGradient(colors: [Color.vLaserBlue, Color.vRpaGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(14)
            }
            
            HStack(spacing: 10) {
                SandboxUtilityStatus(title: "清空队列", icon: "trash.fill", value: "待确认")
                SandboxUtilityStatus(title: "导出演示包", icon: "square.and.arrow.up.fill", value: "已就绪")
            }
        }
    }
}

private struct SandboxScenarioCard: View {
    let scenario: SandboxScenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: scenario.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(scenario.color)
            Text(scenario.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(scenario.detail)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.vCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SandboxStatusPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct SandboxUtilityStatus: View {
    let title: String
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.vCardBg)
        .cornerRadius(12)
    }
}

private struct SandboxScenarioDetailView: View {
    let scenario: SandboxScenario
    
    var body: some View {
        ZStack {
            Color.vBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(scenario.color)
                    Text(scenario.title)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(scenario.detail)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.vCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(spacing: 10) {
                    VoxenInfoRow(icon: "target", title: "目标系统", value: scenario.target, color: scenario.color)
                    VoxenInfoRow(icon: "waveform.path.ecg", title: "注入信号", value: "语音 + Vision + 工位标签", color: .vLaserBlue)
                    VoxenInfoRow(icon: "checkmark.shield.fill", title: "审计策略", value: "保留人工确认节点", color: .vRpaGreen)
                }
                .padding(16)
                .background(Color.vCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("剧本详情")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(Color.vBackground)
    }
}
