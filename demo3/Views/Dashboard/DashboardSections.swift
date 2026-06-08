import SwiftUI

#if os(iOS)
import AVFoundation
import UIKit
#endif

// MARK: - 首页状态胶囊
struct DashboardStatusHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.vRpaGreen)
                    .frame(width: 8, height: 8)
                Text("Voxen Online")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            HStack(spacing: 14) {
                Label("Local SLM", systemImage: "cpu.fill")
                Label("Mesh Active", systemImage: "arkit")
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
    }
}

// MARK: - 核心视听无感捕获中枢
struct DashboardLiveCapturePanel: View {
    @ObservedObject var captureViewModel: LiveAgentCaptureViewModel
    let scanOffset: CGFloat
    let wavePhase: Double
    
    var body: some View {
        ZStack {
            LiveCameraSurface(captureViewModel: captureViewModel)
            DashboardGridBackground()
                .opacity(0.55)
            
            VStack(spacing: 20) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.vLaserBlue.opacity(0.3), lineWidth: 1)
                        .frame(width: 220, height: 220)
                    
                    CornerBorders()
                        .stroke(Color.vLaserBlue, lineWidth: 3)
                        .frame(width: 220, height: 220)
                    
                    Rectangle()
                        .fill(LinearGradient(colors: [Color.vLaserBlue.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 200, height: 4)
                        .offset(y: scanOffset)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<12) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(colors: [Color.vLaserBlue, Color.vRpaGreen], startPoint: .top, endPoint: .bottom))
                                .frame(width: 4, height: waveformHeight(for: index))
                        }
                    }
                }
                
                VStack(spacing: 8) {
                    Text(captureViewModel.transcript)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(stateColor)
                            .frame(width: 7, height: 7)
                        Text(captureViewModel.agentDecision)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(stateColor)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(stateColor.opacity(0.12))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
                
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.vCardBg.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        let phase = sin(wavePhase + Double(index)) * 18
        let micBoost = captureViewModel.micLevel * 58
        return max(16, phase + micBoost + 18)
    }
    
    private var stateColor: Color {
        switch captureViewModel.captureState {
        case .detected:
            return .vRpaGreen
        case .permissionDenied:
            return .vWarningRed
        case .analyzing:
            return .t2WarnOrange
        default:
            return .vLaserBlue
        }
    }
}

private struct LiveCameraSurface: View {
    @ObservedObject var captureViewModel: LiveAgentCaptureViewModel
    
    var body: some View {
        ZStack {
            #if os(iOS)
            CameraPreviewView(session: captureViewModel.cameraSession)
                .overlay(Color.black.opacity(0.22))
            #else
            CameraPreviewFallback()
            #endif
            
            VStack {
                HStack {
                    CaptureSignalPill(title: "Camera", isActive: captureViewModel.captureState != .permissionDenied)
                    CaptureSignalPill(title: "Mic", isActive: captureViewModel.captureState != .permissionDenied)
                    CaptureLanguagePill(title: captureViewModel.detectedSpeechLanguageLabel)
                    Spacer()
                    Image(systemName: "viewfinder")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.vLaserBlue)
                }
                .padding(14)
                
                Spacer()
            }
        }
    }
}

private struct CaptureSignalPill: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.vRpaGreen : Color.vWarningRed)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.32))
        .cornerRadius(8)
    }
}

private struct CaptureLanguagePill: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.vLaserBlue)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.32))
        .cornerRadius(8)
    }
}

private struct CameraPreviewFallback: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.vBackground, Color.vCardBg, Color.black.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56, weight: .thin))
                .foregroundColor(.vLaserBlue.opacity(0.35))
        }
    }
}

#if os(iOS)
private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
#endif

// MARK: - 管理层“效率冰山”核心指标区
struct DashboardAnalyticsSection: View {
    var body: some View {
        HStack(spacing: 14) {
            DashboardOeeMetricCard()
            DashboardFailureTrendCard()
        }
        .frame(height: 140)
        .padding(.horizontal, 16)
    }
}

// MARK: - 快捷演示沙盒与无感任务流转条
struct DashboardSandboxTickerBar: View {
    let logMessage: String
    let tickerIndex: Int
    let onSandboxTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSandboxTap) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                    Text("演示沙盒")
                        .fontWeight(.bold)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.vBackground)
                .frame(width: 120, height: 48)
                .background(LinearGradient(colors: [Color.vLaserBlue, Color.vRpaGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
            VStack(alignment: .leading) {
                Text(logMessage)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .id(tickerIndex)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .bottom).combined(with: .opacity)))
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 48)
            .background(Color.vCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

private struct DashboardGridBackground: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                context.stroke(
                    Path { path in
                        for i in stride(from: 0, to: size.width, by: 30) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: size.height))
                        }
                        for j in stride(from: 0, to: size.height, by: 30) {
                            path.move(to: CGPoint(x: 0, y: j))
                            path.addLine(to: CGPoint(x: size.width, y: j))
                        }
                    },
                    with: .color(Color.white.opacity(0.03)),
                    lineWidth: 1
                )
            }
        }
    }
}

private struct DashboardOeeMetricCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全厂自愈效能")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("89.4%")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.caption)
                        .foregroundColor(.vRpaGreen)
                }
                Text("综合效率 OEE")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 6) {
                Text("捕获隐形故障")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("342 件")
                    .font(.system(.footnote, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.vWarningRed)
            }
        }
        .padding(16)
        .background(Color.vCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct DashboardFailureTrendCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("重复性微故障预测")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(Color.vLaserBlue)
                    .frame(width: 6, height: 6)
            }
            
            GeometryReader { matrix in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: matrix.size.height * 0.7))
                    path.addLine(to: CGPoint(x: matrix.size.width * 0.2, y: matrix.size.height * 0.65))
                    path.addLine(to: CGPoint(x: matrix.size.width * 0.4, y: matrix.size.height * 0.8))
                    path.addLine(to: CGPoint(x: matrix.size.width * 0.6, y: matrix.size.height * 0.4))
                    path.addLine(to: CGPoint(x: matrix.size.width * 0.8, y: matrix.size.height * 0.5))
                }
                .stroke(Color.vLaserBlue, lineWidth: 2)
                
                Path { path in
                    path.move(to: CGPoint(x: matrix.size.width * 0.8, y: matrix.size.height * 0.5))
                    path.addLine(to: CGPoint(x: matrix.size.width * 0.9, y: matrix.size.height * 0.2))
                    path.addLine(to: CGPoint(x: matrix.size.width, y: matrix.size.height * 0.1))
                }
                .stroke(Color.vLaserBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
            }
            .frame(height: 55)
            .padding(.vertical, 4)
            
            Text("⚡ A区吸盘抖动频繁，提示下周停机风险")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.vLaserBlue)
                .lineLimit(1)
        }
        .padding(16)
        .background(Color.vCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - HIG 规范自定义组件：硬核视觉定位四角高亮框
struct CornerBorders: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 20
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        
        return path
    }
}
