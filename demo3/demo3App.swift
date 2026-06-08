//
//  demo3App.swift
//  demo3
//
//  Created by mac on 2026/6/4.
//

import SwiftUI

@main
struct demo3App: App {
    @StateObject private var agentStore = AgentIncidentStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(agentStore)
        }
    }
}
