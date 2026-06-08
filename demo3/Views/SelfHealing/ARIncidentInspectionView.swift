import SwiftUI

#if os(iOS)
@preconcurrency import ARKit
import RealityKit
import UIKit
#endif

// MARK: - RealityKit 现场异常空间标注
struct ARIncidentInspectionView: View {
    @Environment(\.dismiss) private var dismiss
    let incident: IncidentItem
    var onMarkersCommitted: ((Int) -> Void)? = nil
    
    @State private var trackingMessage = "缓慢移动设备，扫描机台或产品表面"
    @State private var markerCount = 0
    @State private var resetToken = UUID()
    
    var body: some View {
        ZStack {
            #if os(iOS)
            ARIncidentSceneView(
                incident: incident,
                trackingMessage: $trackingMessage,
                markerCount: $markerCount,
                resetToken: resetToken
            )
            .ignoresSafeArea()
            #else
            Color(t2Hex: "101422").ignoresSafeArea()
            #endif
            
            VStack(spacing: 0) {
                ARInspectionStatusBar(
                    incident: incident,
                    trackingMessage: trackingMessage,
                    markerCount: markerCount
                )
                
                Spacer()
                
                ARInspectionControlBar(
                    markerCount: markerCount,
                    onCommit: {
                        onMarkersCommitted?(markerCount)
                        if onMarkersCommitted != nil {
                            dismiss()
                        }
                    },
                    onReset: {
                        markerCount = 0
                        trackingMessage = "空间标注已清除，请重新扫描现场"
                        resetToken = UUID()
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationTitle("AR 现场标注")
        .voxenInlineNavigationTitle()
        .voxenNavigationBackground(Color(t2Hex: "101422"))
    }
}

private struct ARInspectionStatusBar: View {
    let incident: IncidentItem
    let trackingMessage: String
    let markerCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(incident.categoryColor.opacity(0.16))
                        .frame(width: 40, height: 40)
                    Image(systemName: incident.categoryIcon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(incident.categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(incident.category)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(incident.location)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Label("\(markerCount)", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.t2Cyan)
            }
            
            HStack(spacing: 7) {
                Circle()
                    .fill(markerCount > 0 ? Color.t2HealGreen : Color.t2WarnOrange)
                    .frame(width: 7, height: 7)
                Text(trackingMessage)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct ARInspectionControlBar: View {
    let markerCount: Int
    let onCommit: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("点击异常位置放置空间标记")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("标记可拖动、旋转与缩放，数据保留在本机")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(markerCount > 0 ? .white : .white.opacity(0.35))
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.42))
                        .clipShape(Circle())
                }
                .disabled(markerCount == 0)
                
                Button(action: onCommit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black.opacity(markerCount > 0 ? 1 : 0.35))
                        .frame(width: 40, height: 40)
                        .background(markerCount > 0 ? Color.t2HealGreen : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(markerCount == 0)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#if os(iOS)
private struct ARIncidentSceneView: UIViewRepresentable {
    let incident: IncidentItem
    @Binding var trackingMessage: String
    @Binding var markerCount: Int
    let resetToken: UUID
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.renderOptions.insert(.disableMotionBlur)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.delegate = context.coordinator
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .anyPlane
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.topAnchor.constraint(equalTo: arView.topAnchor),
            coachingOverlay.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: arView.trailingAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: arView.bottomAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.placeMarker(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        context.coordinator.arView = arView
        context.coordinator.lastResetToken = resetToken
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.parent = self
        guard context.coordinator.lastResetToken != resetToken else { return }
        context.coordinator.lastResetToken = resetToken
        context.coordinator.removeAllMarkers()
    }
    
    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        arView.session.pause()
    }
    
    final class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARIncidentSceneView
        weak var arView: ARView?
        var lastResetToken = UUID()
        
        private var markerAnchors: [AnchorEntity] = []
        private var hasFoundPlane = false
        
        init(parent: ARIncidentSceneView) {
            self.parent = parent
        }
        
        @objc func placeMarker(_ recognizer: UITapGestureRecognizer) {
            guard let arView else { return }
            let point = recognizer.location(in: arView)
            guard let result = arView.raycast(
                from: point,
                allowing: .estimatedPlane,
                alignment: .any
            ).first else {
                parent.trackingMessage = "暂未识别到可锚定表面，请继续移动设备"
                return
            }
            
            let anchor = AnchorEntity(world: result.worldTransform)
            let marker = makeMarkerEntity()
            anchor.addChild(marker)
            arView.scene.addAnchor(anchor)
            arView.installGestures([.translation, .rotation, .scale], for: marker)
            
            markerAnchors.append(anchor)
            parent.markerCount = markerAnchors.count
            parent.trackingMessage = "异常位置已锚定，可移动标记进行精确调整"
            
            var emphasizedTransform = marker.transform
            emphasizedTransform.scale = SIMD3(repeating: 1.18)
            marker.move(
                to: emphasizedTransform,
                relativeTo: marker.parent,
                duration: 0.22,
                timingFunction: .easeOut
            )
        }
        
        func removeAllMarkers() {
            markerAnchors.forEach { $0.removeFromParent() }
            markerAnchors.removeAll()
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard !hasFoundPlane, anchors.contains(where: { $0 is ARPlaneAnchor }) else { return }
            hasFoundPlane = true
            DispatchQueue.main.async { [weak self] in
                self?.parent.trackingMessage = "已识别现场表面，点击异常位置放置标记"
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.trackingMessage = "AR 跟踪暂不可用：\(error.localizedDescription)"
            }
        }
        
        private func makeMarkerEntity() -> ModelEntity {
            let markerColor = UIColor.voxenIncidentColor(for: parent.incident.category)
            let material = SimpleMaterial(
                color: markerColor,
                roughness: 0.24,
                isMetallic: true
            )
            let mesh = MeshResource.generateSphere(radius: 0.035)
            let marker = ModelEntity(mesh: mesh, materials: [material])
            marker.name = "voxen-incident-marker"
            marker.position.y = 0.04
            marker.generateCollisionShapes(recursive: true)
            
            let stemMesh = MeshResource.generateBox(
                size: SIMD3<Float>(0.012, 0.08, 0.012),
                cornerRadius: 0.004
            )
            let stem = ModelEntity(mesh: stemMesh, materials: [material])
            stem.position.y = -0.055
            marker.addChild(stem)
            
            return marker
        }
    }
}

private extension UIColor {
    static func voxenIncidentColor(for category: String) -> UIColor {
        switch category {
        case "电脑终端异常":
            return UIColor.systemBlue
        case "物料即将耗尽":
            return UIColor.systemOrange
        case "机台劣化故障":
            return UIColor.systemRed
        case "产品外观不良":
            return UIColor.systemPurple
        default:
            return UIColor.cyan
        }
    }
}
#endif
