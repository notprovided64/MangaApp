//
//  testView.swift
//  MangaApp
//
//  Created by Preston Clayton on 1/13/24.
//

import SwiftUI

struct testView: View {

    @State private var tapped = false
    @State private var color = Color.red

    var body: some View {
        ZStack {
            Color.gray.opacity(0.5)
                .onTapGesture(count: 2) {
                    color = Color.blue
                }
                .onTapGesture {
                    color = Color.black
                }


            Text("Tap behind this text")
                .padding()
                .background(color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    testView()
}
