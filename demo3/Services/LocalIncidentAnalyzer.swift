import Foundation

// MARK: - 端侧异常判定结果
struct LocalIncidentDecision {
    let response: AgentRecognitionResponse
    let confidence: Double
    let matchedSignals: [String]
    
    var evidenceSummary: String {
        matchedSignals.isEmpty ? "端侧语义规则" : matchedSignals.joined(separator: "、")
    }
}

// MARK: - 端侧优先工业异常分析器
struct LocalIncidentAnalyzer {
    private struct Rule {
        let category: String
        let icon: String
        let targetSystem: String
        let flowTitle: String
        let signals: [String]
        let riskSignals: [String]
        let normalizedDescription: String
    }
    
    private let rules: [Rule] = [
        Rule(
            category: "电脑终端异常",
            icon: "laptopcomputer",
            targetSystem: "企业 ITSM 运维管理系统",
            flowTitle: "开启 AR 终端与网络链路定位",
            signals: ["蓝屏", "死机", "扫码", "扫不进", "电脑", "终端", "usb", "驱动", "网络断", "连不上"],
            riskSignals: ["停机", "无法生产", "全部离线"],
            normalizedDescription: "端侧语义判定工位终端或扫码链路发生异常，需要进入 ITSM 运维流程。"
        ),
        Rule(
            category: "物料即将耗尽",
            icon: "shippingbox.fill",
            targetSystem: "WMS 智能仓储物料申请模块",
            flowTitle: "打开 AR 物料位置与配送路径",
            signals: ["快用完", "用完", "没料", "没有料", "冇料", "缺料", "补料", "送一箱", "库存", "低于", "耗尽"],
            riskSignals: ["停线", "十分钟", "15分钟", "马上用完"],
            normalizedDescription: "端侧语义判定现场物料低于安全水位，需要生成 WMS 备料与配送任务。"
        ),
        Rule(
            category: "机台劣化故障",
            icon: "gearshape.2.fill",
            targetSystem: "EAM 设备资产系统 + 机修无线广播",
            flowTitle: "打开 AR 设备故障空间标注",
            signals: ["气压", "异响", "咔咔", "漏油", "震动", "主轴", "机台", "设备", "温度高", "卡住"],
            riskSignals: ["骤降", "撞针", "冒烟", "危险", "停机", "高温"],
            normalizedDescription: "端侧语义判定设备出现劣化或故障征兆，需要进入 EAM 机修处置流程。"
        ),
        Rule(
            category: "产品外观不良",
            icon: "checkmark.seal.fill",
            targetSystem: "MES 生产执行系统品控模块",
            flowTitle: "打开 AR 瑕疵区域标注与复检",
            signals: ["起泡", "泡泡", "划痕", "裂纹", "变形", "不良", "瑕疵", "脏污", "色差", "脱落"],
            riskSignals: ["整批", "这批", "呢批", "批量", "全部", "超标"],
            normalizedDescription: "端侧语义判定产品存在外观或批次质量异常，需要进入 MES/QC 拦截流程。"
        )
    ]
    
    private let negationSignals = [
        "没有问题", "无异常", "正常运行", "已经修好", "不用处理", "误报", "测试一下"
    ]
    
    func analyze(
        transcript: String,
        speechLanguage: AgentSpeechLanguageProfile,
        micLevel: Double
    ) -> LocalIncidentDecision? {
        let normalizedText = normalize(transcript)
        guard normalizedText.count >= 4 else { return nil }
        guard !negationSignals.contains(where: normalizedText.contains) else { return nil }
        
        let scoredRules = rules.map { rule -> (Rule, [String], [String]) in
            let matches = rule.signals.filter(normalizedText.contains)
            let risks = rule.riskSignals.filter(normalizedText.contains)
            return (rule, matches, risks)
        }
        .filter { !$0.1.isEmpty }
        .sorted {
            ($0.1.count * 2 + $0.2.count * 3) > ($1.1.count * 2 + $1.2.count * 3)
        }
        
        guard let best = scoredRules.first else { return nil }
        
        let signalScore = min(Double(best.1.count) * 0.16, 0.48)
        let riskScore = min(Double(best.2.count) * 0.12, 0.24)
        let speechScore = micLevel >= 0.08 ? 0.08 : 0.03
        let confidence = min(0.48 + signalScore + riskScore + speechScore, 0.97)
        let ticketPrefix = ticketPrefix(for: best.0.category)
        let ticketNumber = "Edge #\(ticketPrefix)-\(Self.shortTimestamp())"
        let language = speechLanguage.displayName
        let matchedSignals = Array((best.1 + best.2).prefix(5))
        let evidenceText = matchedSignals.joined(separator: "、")
        
        let response = AgentRecognitionResponse(
            detected: true,
            originalLanguage: language,
            normalizedTranscript: normalizedText,
            category: best.0.category,
            categoryIcon: best.0.icon,
            translatedText: best.0.normalizedDescription,
            location: "车间 A 区 · A-03 贴膜工位",
            initiator: "现场员工 (\(language)偏好)",
            targetSystem: best.0.targetSystem,
            ticketNumber: ticketNumber,
            details: "端侧规则引擎已在设备内完成初判，命中「\(evidenceText)」等现场信号；无需把原始音频继续上传到 Agent 即可生成处置草稿，等待现场人员复核。",
            flowNodeTitle: best.0.flowTitle,
            confidence: confidence
        )
        
        return LocalIncidentDecision(
            response: response,
            confidence: confidence,
            matchedSignals: matchedSignals
        )
    }
    
    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "唔稳", with: "不稳定")
            .replacingOccurrences(of: "冇", with: "没有")
            .replacingOccurrences(of: "咗", with: "了")
            .replacingOccurrences(of: "呢度", with: "这里")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func ticketPrefix(for category: String) -> String {
        switch category {
        case "电脑终端异常":
            return "ITSM"
        case "物料即将耗尽":
            return "WMS"
        case "机台劣化故障":
            return "EAM"
        default:
            return "QA"
        }
    }
    
    private static func shortTimestamp() -> String {
        String(Int(Date().timeIntervalSince1970) % 100_000)
    }
}
