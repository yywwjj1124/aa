import SwiftUI
internal import Combine

@MainActor
final class VoxenSelfHealingViewModel: ObservableObject {
    // 搜索与过滤核心状态变量
    @Published var searchText = ""
    
    // 当前点击选中准备弹出详情 Sheet 的异常
    @Published var activeSheetIncident: IncidentItem?
    @Published var isShowingHistorySheet = false // 弹出底页历史归档
    @Published var pulseWave = false            // 呼吸波形动画控制
    
    // 模拟数据源 (完美对应 4 个务实剧本)
    let mockIncidents = [
        IncidentItem(
            category: "电脑终端异常",
            categoryIcon: "laptopcomputer",
            categoryColor: .blue,
            originalDialect: "“呢度个屏幕蓝屏咗，扫不进码呀，不知整点。”",
            translatedText: "工位终端 PC 发生 BSoD (蓝屏死机) 故障，扫码枪 USB 驱动假死。",
            location: "车间 B 区 · B-04 包装工位",
            initiator: "李大叔 (包装班组 · 粤语偏好)",
            targetSystem: "企业 ITSM 运维管理系统",
            ticketNumber: "Ticket #ITSM-0819",
            details: "Agent 已自动核对端侧硬件堆栈日志，打包故障 dump 文件写入 IT 服务台。工单已自动派发至「IT 硬件维修一班」排班流转中，现场不自动重启以保护运行数据。",
            flowNodeTitle: "开启 3D AR 网络拓扑定位",
            flowNodeIcon: "arkit"
        ),
        IncidentItem(
            category: "物料即将耗尽",
            categoryIcon: "shippingbox.fill",
            categoryColor: .t2WarnOrange,
            originalDialect: "“吸盘贴纸快用完啦，叉车再送一箱过来呀。”",
            translatedText: "贴膜工位吸盘保护膜低于 10% 安全水位，预计 15 分钟内消耗完毕。",
            location: "车间 A 区 · A-03 贴膜工位",
            initiator: "张大叔 (贴膜班组 · 粤语偏好)",
            targetSystem: "WMS 智能仓储物料申请模块",
            ticketNumber: "Req #WMS-8831",
            details: "系统通过本地备库盘点，自动锁定库房 1 箱备品，自动生成「现场领料申请草稿单」。工单已递交张班长胸麦，等待刷卡确认，符合厂区财务审计流程。",
            flowNodeTitle: "查看 WMS 备品锁料物流追踪",
            flowNodeIcon: "truck.box.fill"
        ),
        IncidentItem(
            category: "机台劣化故障",
            categoryIcon: "gearshape.2.fill",
            categoryColor: .t2WarnRed,
            originalDialect: "“呢度气压唔稳，冲压主轴咔咔响，来个机修呀。”",
            translatedText: "冲压机主轴气压骤降（至 0.45MPa），并伴随高频磨损金属异响，存在撞针风险。",
            location: "车间 C 区 · C-12 冲压工位",
            initiator: "赵大叔 (冲压班组 · 粤语偏好)",
            targetSystem: "EAM 设备资产系统 + 机修无线广播",
            ticketNumber: "EAM-7704",
            details: "触发高频劣化警报。Agent 已将设备故障位置三维空间特征封包，并向值班机修工手环推送强震动告警，机修班长正带上便携工具赶往工位进行处置。",
            flowNodeTitle: "拉起远程 3D 空间维修会诊",
            flowNodeIcon: "phone.bubble.left.fill"
        ),
        IncidentItem(
            category: "产品外观不良",
            categoryIcon: "checkmark.seal.fill",
            categoryColor: .t2QcPurple,
            originalDialect: "“贴膜起泡泡啦，呢批货都有问题，你快来看下。”",
            translatedText: "批量真空覆膜表面出现多处面积超标气泡（气泡占比超 5%），存在批次性工艺异常。",
            location: "车间 D 区 · D-01 组装工位",
            initiator: "刘大叔 (组装班组 · 粤语偏好)",
            targetSystem: "MES 生产执行系统品控模块",
            ticketNumber: "Lot #QA-9051",
            details: "触发质量控制闸门。Agent 已生成临时「批次不合格拦截令」，将 MES 系统内该批次状态锁定。已自动向 QC 主管梁工发送加急复检呼叫，防止不良品外流。",
            flowNodeTitle: "调取端侧 Vision 瑕疵 ROI 细节",
            flowNodeIcon: "eye.fill"
        )
    ]
    
    // 计算属性：根据输入模糊过滤
    func filteredIncidents(liveIncidents: [IncidentItem]) -> [IncidentItem] {
        let allIncidents = liveIncidents + mockIncidents
        
        if searchText.isEmpty {
            return allIncidents
        } else {
            return allIncidents.filter { incident in
                incident.category.localizedCaseInsensitiveContains(searchText) ||
                incident.location.localizedCaseInsensitiveContains(searchText) ||
                incident.initiator.localizedCaseInsensitiveContains(searchText) ||
                incident.translatedText.localizedCaseInsensitiveContains(searchText) ||
                incident.ticketNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func selectIncident(_ incident: IncidentItem) {
        activeSheetIncident = incident
    }
    
    func showHistoryArchive() {
        isShowingHistorySheet = true
    }
    
    func tickPulse() {
        pulseWave.toggle()
    }
}
