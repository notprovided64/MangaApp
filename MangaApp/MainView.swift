//
//  MainView.swift
//  MangaAppTest
//
//  Created by Preston Clayton on 8/18/22.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                .navigationBarTitleDisplayMode(.large)
                .navigationTitle("Manga")

            }
            .tabItem {
                Label("Menu", systemImage: "house")
            }

            NavigationView{
                SearchView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Search")

            }.navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }


        }
    }
}

struct urlDropDelegate: DropDelegate {
    @Binding var items: [Manga]
    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: ["public.url"]) else {
            return false
        }
        
        let items = info.itemProviders(for: ["public.url"])
        for item in items {
            _ = item.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    if url.absoluteString.contains(baseurlString) {
                        Task {
                            do {
                                let manga = try await getMangaFromUrl(url: url)
                                self.items.append(manga)
                            } catch {
                                print("Error fetching manga.")
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView(container: MangaContainer())
//    }
//}
