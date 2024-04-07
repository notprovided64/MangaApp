//
//  SearchView.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/18/22.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var userData: UserData
    
    @State var query: String = ""
    @State var results = [Manga]()
    
    var body: some View {
        List {
            ForEach(results, id: \.self.name) { result in
                NavigationLink {
                    MangaView(manga: result)
                } label: {
                    HStack {
                        PosterView(url: result.image)
                            .frame(height: 220)
                        VStack(alignment: .leading) {
                            Text(result.name)
                                .minimumScaleFactor(0.2)
                            Text("")
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .listStyle(.inset)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .onSubmit(of: .search) {
            search()
        }
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)

    }
    func search() {
        results = []
        Task {
            results = try await getMangasBySearch(query: query)
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{SearchView()}
    }
}
