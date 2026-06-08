import SwiftUI

struct VoxenLoginView: View {
    @StateObject private var viewModel = VoxenLoginViewModel()
    @State private var logoPulse = false
    @State private var scanSweep: CGFloat = -90
    let onAuthenticated: () -> Void
    
    var body: some View {
        ZStack {
            Color.vBackground
                .ignoresSafeArea()
            
            LoginGridBackground()
                .opacity(0.42)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    VoxenLoginLogo(pulse: logoPulse)
                    
                    VStack(spacing: 16) {
                        VoxenLoginModePicker(
                            selectedMode: viewModel.selectedMode,
                            onSelect: viewModel.switchMode
                        )
                        
                        Group {
                            switch viewModel.selectedMode {
                            case .employeePassword:
                                EmployeePasswordLoginForm(
                                    employeeId: $viewModel.employeeId,
                                    password: $viewModel.password
                                )
                                .transition(.move(edge: .leading).combined(with: .opacity))
                            case .nfcPin:
                                NfcPinLoginForm(
                                    pinCode: $viewModel.pinCode,
                                    isNfcLinked: viewModel.isNfcLinked,
                                    isScanning: viewModel.isAuthenticating,
                                    scanSweep: scanSweep,
                                    onScan: viewModel.scanNfcCard
                                )
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        
                        LoginStatusStrip(message: viewModel.loginMessage, isBusy: viewModel.isAuthenticating)
                        
                        Button {
                            viewModel.submit(onAuthenticated: onAuthenticated)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isAuthenticating ? "lock.rotation" : "arrow.right.circle.fill")
                                Text(viewModel.selectedMode == .employeePassword ? "进入 Voxen" : "PIN 安全进入")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.vBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: viewModel.canSubmit ? [Color.vLaserBlue, Color.vRpaGreen] : [Color.white.opacity(0.25), Color.white.opacity(0.16)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.vLaserBlue.opacity(viewModel.canSubmit ? 0.26 : 0), radius: 14, y: 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canSubmit || viewModel.isAuthenticating)
                    }
                    .padding(16)
                    .background(Color.vCardBg.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    LoginSecurityBadges()
                }
                .padding(.top, 75)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                logoPulse = true
            }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                scanSweep = 90
            }
        }
    }
}

private struct VoxenLoginLogo: View {
    let pulse: Bool
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.vLaserBlue.opacity(0.2), lineWidth: 16)
                    .frame(width: 116, height: 116)
                    .scaleEffect(pulse ? 1.08 : 0.94)
                
                Circle()
                    .fill(Color.vCardBg)
                    .frame(width: 94, height: 94)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [Color.vLaserBlue, Color.vRpaGreen], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    )
                
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.vLaserBlue, Color.vRpaGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(pulse ? 1.04 : 0.98)
            }
            
            VStack(spacing: 2) {
                Text("Voxen维讯")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Industrial Multimodal Agent")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
}

private struct VoxenLoginModePicker: View {
    let selectedMode: VoxenLoginMode
    let onSelect: (VoxenLoginMode) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(VoxenLoginMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(selectedMode == mode ? .vBackground : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(selectedMode == mode ? Color.vLaserBlue : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct EmployeePasswordLoginForm: View {
    @Binding var employeeId: String
    @Binding var password: String
    
    var body: some View {
        VStack(spacing: 12) {
            LoginField(icon: "person.badge.key.fill", title: "工号", placeholder: "VX-0819", text: $employeeId)
            
            LoginSecureField(icon: "lock.fill", title: "密码", placeholder: "••••••••", text: $password)
        }
    }
}

private struct NfcPinLoginForm: View {
    @Binding var pinCode: String
    let isNfcLinked: Bool
    let isScanning: Bool
    let scanSweep: CGFloat
    let onScan: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onScan) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.22))
                        .frame(height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isNfcLinked ? Color.vRpaGreen : Color.vLaserBlue.opacity(0.55), lineWidth: 1)
                        )
                    
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Color.vLaserBlue.opacity(0.32), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 2)
                        .offset(y: isScanning ? scanSweep : 0)
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill((isNfcLinked ? Color.vRpaGreen : Color.vLaserBlue).opacity(0.16))
                                .frame(width: 58, height: 58)
                            Image(systemName: isNfcLinked ? "checkmark.seal.fill" : "wave.3.right.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(isNfcLinked ? .vRpaGreen : .vLaserBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(isNfcLinked ? "VX 工卡已读取" : "读取 VX 工卡")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(isNfcLinked ? "NFC Secure Element Linked" : "NFC Card Waiting")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                }
            }
            .buttonStyle(.plain)
            
            PinCodeField(pinCode: $pinCode)
        }
    }
}

private struct LoginField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.vLaserBlue)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                TextField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(Color.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct LoginSecureField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.vLaserBlue)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                SecureField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(Color.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PinCodeField: View {
    @Binding var pinCode: String
    @FocusState private var isPinFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("6 位 PIN", systemImage: "number")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            
            ZStack {
                HStack(spacing: 8) {
                    ForEach(0..<6) { index in
                        PinDigitBox(isFilled: index < pinCode.count)
                    }
                }
                
                TextField("", text: filteredPinBinding)
                    .voxenPinKeyboard()
                    .foregroundColor(Color.clear)
                    .accentColor(Color.clear)
                    .focused($isPinFocused)
                    .frame(maxWidth: CGFloat.infinity)
                    .frame(height: 46)
                    .opacity(0.02)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isPinFocused = true
            }
        }
        .frame(height: 76)
    }
    
    private var filteredPinBinding: Binding<String> {
        Binding(
            get: { pinCode },
            set: { pinCode = String($0.filter { $0.isNumber }.prefix(6)) }
        )
    }
}

private extension View {
    @ViewBuilder
    func voxenPinKeyboard() -> some View {
        #if os(iOS)
        self
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
        #else
        self
        #endif
    }
}

private struct PinDigitBox: View {
    let isFilled: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.black.opacity(0.22))
            .frame(height: 46)
            .overlay(
                Text(isFilled ? "•" : "")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isFilled ? Color.vRpaGreen : Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct LoginStatusStrip: View {
    let message: String
    let isBusy: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isBusy ? Color.t2WarnOrange : Color.vRpaGreen)
                .frame(width: 7, height: 7)
            Text(message)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LoginSecurityBadges: View {
    var body: some View {
        HStack(spacing: 10) {
            SecurityBadge(icon: "cpu.fill", title: "Edge ID")
            SecurityBadge(icon: "lock.shield.fill", title: "Zero Trust")
            SecurityBadge(icon: "dot.radiowaves.left.and.right", title: "NFC Ready")
        }
        .padding(.horizontal, 18)
    }
}

private struct SecurityBadge: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }
}

private struct LoginGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 38
            var path = Path()
            
            stride(from: CGFloat(0), through: size.width, by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 0.6)
        }
    }
}

struct VoxenLoginView_Previews: PreviewProvider {
    static var previews: some View {
        VoxenLoginView {}
            .preferredColorScheme(.dark)
    }
}
