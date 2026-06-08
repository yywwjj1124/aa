import SwiftUI

struct ArchiveEventDetailView: View {
    let event: ArchiveEvent
    
    var body: some View {
        ZStack {
            Color(t2Hex: "101422")
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(event.category)
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(event.status)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.t2HealGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.t2HealGreen.opacity(0.12))
                                .cornerRadius(8)
                        }
                        
                        Text(event.detail)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color.t2SlateCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    VStack(spacing: 10) {
                        VoxenInfoRow(icon: "calendar", title: "归档日期", value: event.date, color: .t2Cyan)
                        VoxenInfoRow(icon: "mappin.and.ellipse", title: "工位", value: event.position, color: .t2WarnOrange)
                        VoxenInfoRow(icon: "person.2.fill", title: "责任组", value: event.owner, color: .t2HealGreen)
                        VoxenInfoRow(icon: "server.rack", title: "闭环系统", value: event.system, color: .t2QcPurple)
                    }
                    .padding(16)
                    .background(Color.t2SlateCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("闭环审计轨迹")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        VoxenFlowStepRow(index: "01", title: "异常采集", detail: "端侧记录原始语音/视觉证据，并生成最小必要摘要。", color: .t2Cyan)
                        VoxenFlowStepRow(index: "02", title: "系统流转", detail: "按工位、角色、目标系统自动路由，人工节点完成确认。", color: .t2HealGreen)
                        VoxenFlowStepRow(index: "03", title: "归档冻结", detail: "保留工单编号、时间线、处置人和业务系统回写状态。", color: .t2QcPurple)
                    }
                    .padding(16)
                    .background(Color.t2SlateCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(16)
            }
        }
        .navigationTitle("归档详情")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(Color(t2Hex: "101422"))
    }
}
