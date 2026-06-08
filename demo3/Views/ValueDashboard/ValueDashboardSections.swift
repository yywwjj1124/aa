import SwiftUI
import Charts

// MARK: - 顶部标题与整体挽回价值核心宣告
struct ValueDashboardHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("价值看板")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Value Dashboard")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("挽回 OEE 隐形损失 (本月)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text("+4.8%")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(T3Colors.vHealGreen)
                    .shadow(color: T3Colors.vHealGreen.opacity(0.3), radius: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}

// MARK: - 核心效益指标组
struct ValueMetricSummarySection: View {
    var body: some View {
        HStack(spacing: 10) {
            HeroMetricCard(
                title: "阻断停机损失",
                value: "72.4 Hrs",
                subtitle: "本月累积抢回",
                icon: "clock.badge.checkmark.fill",
                color: T3Colors.vLaserCyan
            )
            
            HeroMetricCard(
                title: "决策分派准确率",
                value: "99.2%",
                subtitle: "零错流转路由",
                icon: "arrow.triangle.2.circlepath",
                color: T3Colors.vHealGreen
            )
            
            HeroMetricCard(
                title: "方言译轨置信度",
                value: "94.6%",
                subtitle: "端侧 SLM 粤/川",
                icon: "character.bubble.fill",
                color: T3Colors.vQcPurple
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 停机阻断对比
struct DowntimeComparisonSection: View {
    let downtimeData: [DowntimeData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("生产线异常停机阻断时长对比")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Downtime Intercepted (传统报修流程 vs Voxen 秒级流转)")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Chart(downtimeData) { item in
                BarMark(
                    x: .value("异常分类", item.category),
                    y: .value("停机时长 (小时)", item.hours)
                )
                .foregroundStyle(by: .value("流程类型", item.processType))
                .position(by: .value("流程类型", item.processType))
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartForegroundStyleScale([
                "传统停机损失": AnyShapeStyle(T3Colors.vMutedGray),
                "Voxen 智能拦截": AnyShapeStyle(
                    LinearGradient(
                        colors: [T3Colors.vLaserCyan, T3Colors.vHealGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            ])
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color.white)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let category = value.as(String.self) {
                            Text(category)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.9))
                        }
                    }
                }
            }
            
            DowntimeLegend()
                .padding(.top, 4)
        }
        .padding(16)
        .background(T3Colors.vSlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
    }
}

// MARK: - 核心工位劣化趋势回归预测
struct DegradationForecastSection: View {
    let points: [DegradationPoint]
    let animatePulse: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DegradationForecastHeader()
            DegradationForecastChart(points: points)
            DegradationForecastDecisionNote(animatePulse: animatePulse)
                .padding(.top, 4)
        }
        .padding(16)
        .background(T3Colors.vSlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - HIG 辅助子组件：核心效益指标卡
private struct HeroMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 8, design: .rounded))
                    .foregroundColor(color.opacity(0.8))
                    .padding(.top, 1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(T3Colors.vSlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
        )
    }
}

private struct DowntimeLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                Circle().fill(T3Colors.vMutedGray).frame(width: 8, height: 8)
                Text("传统人工提报 (本月停机阻尼：77.0h)")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 5) {
                Circle().fill(T3Colors.vLaserCyan).frame(width: 8, height: 8)
                Text("维讯无感路由 (本月实际损耗：5.3h)")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

private struct DegradationForecastHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("A-03工位：设备劣化趋势时序预测")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: "cpu")
                    .font(.caption2)
                    .foregroundColor(T3Colors.vGoldYellow)
            }
            Text("CreateML 本地时序回归算法（振动与气压演变曲线）")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

private struct DegradationForecastChart: View {
    let points: [DegradationPoint]
    
    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("日期", point.day),
                    y: .value("物理劣化度", point.index)
                )
                .foregroundStyle(point.isPredicted ? T3Colors.vGoldYellow : T3Colors.vLaserCyan)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, dash: point.isPredicted ? [4, 4] : []))
                
                AreaMark(
                    x: .value("日期", point.day),
                    y: .value("物理劣化度", point.index)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            point.isPredicted ? T3Colors.vGoldYellow.opacity(0.12) : T3Colors.vLaserCyan.opacity(0.12),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            RuleMark(y: .value("停机阈值", 85.0))
                .foregroundStyle(T3Colors.vWarningRed.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                .annotation(position: .top, alignment: .leading) {
                    Text("物理停机阈值 (85%) - 越过即发生断崖式停产损失")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(T3Colors.vWarningRed)
                }
        }
        .frame(height: 160)
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 85, 100]) { value in
                AxisValueLabel {
                    if let index = value.as(Double.self) {
                        Text("\(Int(index))%")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(index == 85 ? T3Colors.vWarningRed : Color.white)
                            .fontWeight(index == 85 ? .bold : .regular)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let day = value.as(String.self) {
                        Text(day)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(Color.white)
                    }
                }
            }
        }
    }
}

private struct DegradationForecastDecisionNote: View {
    let animatePulse: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(T3Colors.vGoldYellow)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatePulse ? 1.3 : 1.0)
                Text("预测周六劣化度将突破 85% 红线（停产损失：~50k/小时）")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(T3Colors.vGoldYellow)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(T3Colors.vHealGreen)
                Text("已在周五提前完成 IT/OT 维护排班，零阻尼配齐 WMS 电子扫码配件")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.leading, 14)
        }
    }
}

