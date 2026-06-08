//
//  ContentView.swift
//  demo3
//
//  Created by mac on 2026/6/4.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        ZStack {
            if isAuthenticated {
                VoxenMainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                VoxenLoginView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        isAuthenticated = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }
}

struct VoxenMainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VoxenDashboardView()
                .tabItem {
                    Label("感知", systemImage: "waveform.badge.magnifyingglass")
                }
                .tag(0)
            
            VoxenSelfHealingView()
                .tabItem {
                    Label("状态", systemImage: "bolt.shield.fill")
                }
                .tag(1)
            
            VoxenValueDashboardView()
                .tabItem {
                    Label("价值", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
            
            VoxenProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
        .tint(Color.vLaserBlue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AgentIncidentStore())
            .preferredColorScheme(.dark)
    }
}
