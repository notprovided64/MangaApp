//
//  PosterView.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/18/22.
//

import SwiftUI

struct PosterView: View {
    let url: String
    
    var body: some View {
        AsyncImage(url: URL(string: url), content: { image in
            image.resizable()
        }, placeholder: {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                Spacer()
            }
        })
            .aspectRatio(2/3, contentMode: .fit)
            .cornerRadius(8)
            .shadow(radius: 5)
            .padding()
    }
}

struct PosterView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140)) ], spacing: 10) {
                ForEach(["https://www.swahilimodern.com/cdn/shop/products/ndc42a_1_1024x1024.jpg?v=1647903079", "https://m.media-amazon.com/images/I/719U5Q6BSML._AC_UF350,350_QL80_.jpg", "https://www.everwilde.com/media/0800/VGOUBIR-A-Birdhouse-Bottle-Gourd-Seeds.jpg", "dog", "cat", "meow meow"], id: \.self) { url in
                    PosterView(url: url)
                    .cornerRadius(15)
                }
            }
        }
        .padding()
    }
}
