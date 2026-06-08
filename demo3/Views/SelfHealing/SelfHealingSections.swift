import SwiftUI

// MARK: - 状态中心标题头
struct SelfHealingHeader: View {
    let pulseWave: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("状态中心")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Status Center")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.t2HealGreen)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseWave ? 1.25 : 1.0)
                Text("Agent 决策链畅通")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.t2HealGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.t2HealGreen.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }
}

// MARK: - Apple 极简科技感搜索框组件
struct IncidentSearchBar: View {
    @Binding var searchText: String
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            TextField("搜索异常工单、工位或提报人...", text: $searchText)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white)
                .incidentSearchTextBehavior()
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.spring()) {
                        onClear()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

private extension View {
    @ViewBuilder
    func incidentSearchTextBehavior() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
        #else
        self
            .disableAutocorrection(true)
        #endif
    }
}

// MARK: - 实时异常状态流列表
struct IncidentQueueSection: View {
    let incidents: [IncidentItem]
    let onSelect: (IncidentItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("当前工位异常队列", systemImage: "bolt.shield.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(incidents.count) 个匹配")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 4)
            
            if incidents.isEmpty {
                IncidentEmptyState()
            } else {
                VStack(spacing: 12) {
                    ForEach(incidents) { incident in
                        Button(action: {
                            onSelect(incident)
                        }) {
                            IncidentRow(incident: incident)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 底部历史归档折叠入口
struct IncidentHistoryArchiveEntry: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近 30 天已归档闭环事件")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "archivebox.fill")
                        .foregroundColor(.white)
                    Text("查看历史归档 (30天内)")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("142 件已闭环")
                        .font(.caption)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.t2SlateCard)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct IncidentRow: View {
    let incident: IncidentItem
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(incident.categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: incident.categoryIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(incident.categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(incident.category)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(incident.location)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text(incident.ticketNumber)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(incident.categoryColor)
                        .frame(width: 6, height: 6)
                    Text("决策流转中")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(incident.categoryColor)
                }
            }
        }
        .padding(14)
        .background(Color.t2SlateCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

private struct IncidentEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.folder")
                .font(.system(size: 30))
                .foregroundColor(.white)
            Text("未找到相关异常记录")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.t2SlateCard)
        .cornerRadius(16)
    }
}

// MARK: - 核心状态详情模态 Sheet
struct IncidentDetailSheetView: View {
    @Environment(\.dismiss) var dismiss
    let incident: IncidentItem
    @State private var animateButton = false
    @State private var isShowingActionFlow = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(t2Hex: "101422")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    IncidentDetailHeader(incident: incident, onDismiss: dismiss)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            IncidentTranslationCard(incident: incident)
                            IncidentActorCard(incident: incident)
                            IncidentRoutingCard(incident: incident)
                            IncidentNextActionButton(
                                incident: incident,
                                animateButton: animateButton,
                                onTap: { isShowingActionFlow = true }
                            )
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingActionFlow) {
                IncidentActionFlowView(incident: incident)
            }
            .voxenNavigationBackground(Color(t2Hex: "101422"))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateButton = true
            }
        }
    }
}

// MARK: - 模拟历史归档半屏列表视图
struct T2HistoryArchiveSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(t2Hex: "101422")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HistoryArchiveSheetHeader(onDismiss: dismiss)
                    HistoryArchiveList()
                }
            }
            .navigationDestination(for: ArchiveEvent.self) { event in
                ArchiveEventDetailView(event: event)
            }
            .voxenNavigationBackground(Color(t2Hex: "101422"))
        }
    }
}

private struct IncidentDetailHeader: View {
    let incident: IncidentItem
    let onDismiss: DismissAction
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: incident.categoryIcon)
                    .font(.system(size: 10, weight: .bold))
                Text(incident.category)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundColor(incident.categoryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(incident.categoryColor.opacity(0.12))
            .cornerRadius(8)
            
            Spacer()
            
            Button(action: { onDismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

private struct IncidentTranslationCard: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(incident.translatedText)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 9))
                    .foregroundColor(.t2Cyan)
                Text(incident.originalDialect)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.t2Cyan.opacity(0.8))
                    .italic()
                    .lineLimit(2)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(20)
    }
}

private struct IncidentActorCard: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("物理工位", systemImage: "mappin.and.ellipse")
                    .foregroundColor(.white)
                Spacer()
                Text(incident.location)
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.white.opacity(0.06))
            
            HStack {
                Label("异常提报人", systemImage: "person.crop.circle")
                    .foregroundColor(.white)
                Spacer()
                Text(incident.initiator)
                    .foregroundColor(.white)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .padding(16)
        .background(Color.t2SlateCard)
        .cornerRadius(18)
    }
}

private struct IncidentRoutingCard: View {
    let incident: IncidentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundColor(.t2HealGreen)
                Text("Voxen Edge 异常分派流转中")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.t2HealGreen)
                Spacer()
                Text(incident.ticketNumber)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 8) {
                Label("Agent", systemImage: "point.3.filled.connected.trianglepath.dotted")
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.white)
                Spacer()
                Label(incident.targetSystem, systemImage: "server.rack")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)
            
            Text(incident.details)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.t2SlateCard)
        .cornerRadius(18)
    }
}

private struct IncidentNextActionButton: View {
    let incident: IncidentItem
    let animateButton: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: incident.flowNodeIcon)
                Text(incident.flowNodeTitle)
                    .fontWeight(.bold)
            }
            .font(.system(size: 14, design: .rounded))
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
            .shadow(color: Color.t2Cyan.opacity(animateButton ? 0.35 : 0.15), radius: animateButton ? 10 : 5)
            .scaleEffect(animateButton ? 1.01 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct HistoryArchiveSheetHeader: View {
    let onDismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("近30天事件归档")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("已成功阻断并精准流转 142 起隐形劣化与异常")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .padding(.bottom, 16)
    }
}

private struct HistoryArchiveList: View {
    private let events = [
        ArchiveEvent(date: "06-04", category: "💻 ITSM", position: "B-04 包装", detail: "已向 IT 服务台派单，蓝屏终端离线检测", status: "已确认", owner: "IT 硬件维修一班", system: "企业 ITSM 运维管理系统"),
        ArchiveEvent(date: "06-03", category: "⚙️ 机修", position: "A-01 传动", detail: "主轴轴承摩擦异响 ➔ 挂接 EAM 工单呼叫", status: "已结案", owner: "机修值班组", system: "EAM 设备资产系统"),
        ArchiveEvent(date: "06-02", category: "📦 仓储", position: "C-09 组装", detail: "螺纹垫片低于 10% ➔ WMS 备库自动配给", status: "已配给", owner: "WMS 仓储班组", system: "WMS 智能仓储模块"),
        ArchiveEvent(date: "06-01", category: "⚠️ 品控", position: "D-05 覆膜", detail: "Vision 锁起泡异常 ➔ QC 现场开卡质检拦截", status: "已流转", owner: "QC 复检主管", system: "MES 品控模块"),
        ArchiveEvent(date: "05-29", category: "💻 ITSM", position: "B-12 仓位", detail: "手持终端扫码冲突 ➔ 自动向后台补报队列", status: "已重试", owner: "终端运维小组", system: "ITSM + 离线补报队列")
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        ArchiveRow(event: event)
                    }
                    .listRowBackground(Color(t2Hex: "161C2C"))
                }
            } header: {
                Text("近期已闭环异常事件")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

private struct ArchiveRow: View {
    let event: ArchiveEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Text(event.date)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.category)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("•")
                        .foregroundColor(.white)
                    Text(event.position)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(event.detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            
            Text(event.status)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.t2HealGreen)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.t2HealGreen.opacity(0.12))
                .cornerRadius(4)
        }
        .padding(.vertical, 2)
    }
}
