import SwiftUI

// MARK: - 一线工匠个人卡片
struct ProfileWorkerCard: View {
    @Binding var selectedDialect: String
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    Text("张")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("张大叔")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("冲压二班")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                    }
                    
                    Text("工号: #VX-0942  |  一线操作工")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            Divider().background(Color.white.opacity(0.06))
            DialectPreferenceRow(selectedDialect: $selectedDialect)
        }
        .padding(16)
        .background(T4Colors.vSlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - 工位绑定管理
struct WorkstationBindingCard: View {
    let isNfcScanning: Bool
    let isNfcLinked: Bool
    let onNfcTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("工位空间计算绑定", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(isNfcLinked ? "已绑定工位" : "等待刷卡")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(isNfcLinked ? T4Colors.vHealGreen : T4Colors.vOrangeAlert)
            }
            
            HStack(spacing: 12) {
                NfcTagButton(
                    isNfcScanning: isNfcScanning,
                    isNfcLinked: isNfcLinked,
                    onTap: onNfcTap
                )
                
                WorkstationStatusText(isNfcLinked: isNfcLinked)
                Spacer()
            }
            .padding(12)
            .background(Color.black.opacity(0.15))
            .cornerRadius(14)
            
            VisionVerificationRow()
        }
        .padding(16)
        .background(T4Colors.vSlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }
}

// MARK: - 设备安全保障与企业管控
struct DeviceSecuritySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("工业智能终端防卷锁控", systemImage: "shield.righthalf.filled")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                MdmStatusRow(title: "Apple MDM 企业描述文件安全下发", desc: "Apple Configurator 托管控制中", isOk: true)
                Divider().background(Color.white.opacity(0.05))
                MdmStatusRow(title: "工位端单 App 锁屏模式 (SAM)", desc: "已屏蔽非生产娱乐软件入口", isOk: true)
                Divider().background(Color.white.opacity(0.05))
                MdmStatusRow(title: "生产隐私合规保护白名单", desc: "本地音频缓冲区 5s 即听即焚，完全离线运行", isOk: true)
            }
        }
        .padding(16)
        .background(T4Colors.vSlateCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }
}

// MARK: - 标准 Apple Style 注销 / 退出系统按钮
struct ProfileLogoutButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "power")
                    .font(.system(size: 14, weight: .bold))
                Text("退出系统并安全锁屏")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(T4Colors.vWarningRed)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(T4Colors.vSlateCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(T4Colors.vWarningRed.opacity(0.35), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - NFC 刷卡成功全息 Toast 提示
struct NfcSuccessToast: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .foregroundColor(.black)
                Text("NFC 物理工位配对成功")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(T4Colors.vHealGreen)
            .cornerRadius(20)
            .shadow(color: T4Colors.vHealGreen.opacity(0.4), radius: 10)
            .padding(.bottom, 90)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct DialectPreferenceRow: View {
    @Binding var selectedDialect: String
    
    var body: some View {
        HStack {
            Label("端侧 SLM 方言自适应", systemImage: "text.bubble.fill")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            
            Menu {
                Button("粤语 (佛山顺德口音)", action: { selectedDialect = "粤语 (佛山顺德口音)" })
                Button("四川话 (绵阳口音)", action: { selectedDialect = "四川话 (绵阳口音)" })
                Button("普通话 (南方口音纠偏)", action: { selectedDialect = "普通话 (南方口音纠偏)" })
            } label: {
                HStack(spacing: 4) {
                    Text(selectedDialect)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundColor(T4Colors.vDialectPurple)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(T4Colors.vDialectPurple.opacity(0.12))
                .cornerRadius(8)
            }
        }
    }
}

private struct NfcTagButton: View {
    let isNfcScanning: Bool
    let isNfcLinked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isNfcLinked ? T4Colors.vHealGreen.opacity(0.08) : T4Colors.vOrangeAlert.opacity(0.08))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isNfcLinked ? T4Colors.vHealGreen.opacity(0.2) : T4Colors.vOrangeAlert.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: isNfcScanning ? "sensor.tag.radiowaves.forward.fill" : "lock.shield.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isNfcLinked ? T4Colors.vHealGreen : T4Colors.vOrangeAlert)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct WorkstationStatusText: View {
    let isNfcLinked: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isNfcLinked {
                Text("车间 A 区 · A-03 贴膜工位")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("物理 NFC 电子标签匹配成功")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("工位未绑定")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(T4Colors.vOrangeAlert)
                Text("请轻触左侧图标模拟 NFC 贴卡配对")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

private struct VisionVerificationRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .font(.system(size: 12))
                .foregroundColor(T4Colors.vLaserCyan)
            Text("Vision 视觉特征工位校验已启用")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Circle()
                .fill(T4Colors.vLaserCyan)
                .frame(width: 5, height: 5)
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .cornerRadius(10)
    }
}

// MARK: - HIG 辅助子组件：MDM 锁控行
private struct MdmStatusRow: View {
    let title: String
    let desc: String
    let isOk: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isOk ? "lock.shield.fill" : "exclamationmark.shield.fill")
                .font(.system(size: 12))
                .foregroundColor(isOk ? T4Colors.vHealGreen : T4Colors.vWarningRed)
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            Spacer()
            
            Text(isOk ? "安全" : "异常")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(isOk ? T4Colors.vHealGreen : T4Colors.vWarningRed)
        }
    }
}
