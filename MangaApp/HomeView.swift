//
//  HomeView.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/17/22.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userData: UserData
    
    let columns = [GridItem(.adaptive(minimum: 140)) ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(userData.items, id: \.self.link) { manga in
                    NavigationLink {
                        MangaView(manga: manga)
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        PosterView(url: manga.image)
                    }
                    .cornerRadius(15)
                    .contextMenu {
                        Button(role: .destructive) {
                            userData.items.removeAll(where: {$0 == manga})
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }


                }
            }
            .padding()
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView(userData: UserData())
//    }
//}
