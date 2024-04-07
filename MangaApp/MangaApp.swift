//
//  MangaAppTestApp.swift
//  MangaAppTest
//
//  Created by Preston Clayton on 8/15/22.
//

import SwiftUI

@main
struct MangaApp: App {
    @StateObject var userData = UserData()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainView()
            .onChange(of: scenePhase) { phase in
                if phase == .inactive {
                    Task {
                        do {
                            try await UserData.save(series: userData.items)
                        } catch {
                            fatalError("Error saving data.")
                        }
                    }
                }
            }
            .task {
                do {
                    userData.items = try await UserData.load()
                } catch {
                    fatalError("Error loading data.")
                }
            }
            .environmentObject(userData)
            .tint(.green)
        }
    }
}
