import SwiftUI

// MARK: - 统一深色导航背景
struct VoxenNavigationBackground: ViewModifier {
    let color: Color
    
    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbarBackground(color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        #else
        content
        #endif
    }
}

extension View {
    func voxenNavigationBackground(_ color: Color) -> some View {
        modifier(VoxenNavigationBackground(color: color))
    }
    
    @ViewBuilder
    func voxenInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: - 通用信息行
struct VoxenInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 22)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
        .background(Color.white.opacity(0.035))
        .cornerRadius(10)
    }
}

// MARK: - 通用流程节点
struct VoxenFlowStepRow: View {
    let index: String
    let title: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(index)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(3)
            }
            
            Spacer()
        }
    }
}
