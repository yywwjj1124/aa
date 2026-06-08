import SwiftUI

struct SecureLockScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLocked = false
    
    var body: some View {
        ZStack {
            T4Colors.vDarkBg
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.08))
                        .frame(width: 112, height: 112)
                    Circle()
                        .stroke(statusColor.opacity(0.22), lineWidth: 1)
                        .frame(width: 112, height: 112)
                    Image(systemName: isLocked ? "checkmark.shield.fill" : "lock.shield.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(statusColor)
                }
                
                VStack(spacing: 6) {
                    Text(isLocked ? "终端已安全锁定" : "安全锁屏确认")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(isLocked ? "当前工位会话已冻结，MDM 单 App 锁屏策略生效，等待下一次 NFC 工牌刷卡恢复。" : "退出后将冻结当前工位会话，保留最近 5 秒本地音频缓冲审计状态，并回到受管单 App 锁屏模式。")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                
                VStack(spacing: 10) {
                    VoxenInfoRow(icon: "person.crop.circle", title: "当前账号", value: "张大叔 · #VX-0942", color: T4Colors.vDialectPurple)
                    VoxenInfoRow(icon: "mappin.and.ellipse", title: "绑定工位", value: "车间 A 区 · A-03 贴膜工位", color: T4Colors.vLaserCyan)
                    VoxenInfoRow(icon: "shield.righthalf.filled", title: "MDM 状态", value: "托管锁控中", color: T4Colors.vHealGreen)
                }
                .padding(16)
                .background(T4Colors.vSlateCard)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
                
                Spacer()
                
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.spring()) {
                            isLocked = true
                        }
                    }) {
                        Label(isLocked ? "锁屏状态已生效" : "确认退出并锁屏", systemImage: isLocked ? "checkmark.circle.fill" : "power")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(statusColor)
                            .cornerRadius(14)
                    }
                    .disabled(isLocked)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Label(isLocked ? "返回个人中心" : "保持当前会话", systemImage: "arrow.uturn.left")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(T4Colors.vSlateCard)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("安全锁屏")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(T4Colors.vDarkBg)
    }
    
    private var statusColor: Color {
        isLocked ? T4Colors.vHealGreen : T4Colors.vWarningRed
    }
}
