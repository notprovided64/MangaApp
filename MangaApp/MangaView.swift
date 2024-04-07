//
//  MangaView.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/18/22.
//

import SwiftUI

struct MangaView: View {
    @EnvironmentObject var userData: UserData
    
    @ObservedObject var manga: Manga
    @State var saved: Bool = false
    
    var listResults: [Chapter] {
        var result: [Chapter]
        if manga.readingByChapter {
            result = manga.chapters
        } else {
            result = manga.volumes
        }
        
        result = result.filter { $0.lang == manga.langPref }
        
        return result
    }
    
    var listResultsOrdered: [Chapter] {
        var result = listResults
        
        if !manga.lastToFirst {
            result = result.reversed()
        }
        
        return result
    }
    
    var body: some View {
        ScrollView() {
            HStack {
                VStack {
                    Text(manga.name)
                        .font(.largeTitle)
                        .minimumScaleFactor(0.2)
                }
                .padding()
                PosterView(url: manga.image)
            }
            .frame(height:250)

            HStack {
                Text(manga.readingByChapter ? "Chapters" : "Volumes")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        manga.readingByChapter.toggle()
                    }
                Spacer()
                Text("Language")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Picker("Language", selection: $manga.langPref) {
                    ForEach(Lang.allCases, id: \.self) { lang in
                        Text(lang.rawValue)
                            .tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .background(
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundColor( Color(.systemFill))
                )
                Toggle("Jeff", isOn: $manga.lastToFirst)
                    .toggleStyle(SortOrderStyle())

            }
            .padding()
            .background(Material.ultraThick)

            ForEach(listResultsOrdered, id: \.link) { chapter in
                if chapter.lang == manga.langPref {
                    ChapterRow(chapter: chapter, chapters: listResults, readerMode: manga.readingByChapter)
                    Divider()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Toggle(isOn: $saved, label: {
                    Label("Saved", systemImage: "plus")
                })
                .onChange(of: saved, perform: { _ in
                    if !saved {
                        deleteAction()
                    } else {
                        saveAction()
                    }})
                .padding()
            }
        }
        .refreshable {
            await loadChapters()
            await loadVolumes()
        }
        .onAppear {
            saved = userData.items.contains(where: {$0 == manga})
        }
        .task {
            if manga.chapters == [] {
                await loadChapters()
            }
            if manga.volumes == [] {
                await loadVolumes()
            }
        }
    }
    
    func saveAction() {
        if !userData.items.contains(where: {$0 == manga}) {
            userData.items.append(manga)
        }
    }
    func deleteAction() {
        userData.items.removeAll(where: {$0 == manga})
    }

    @MainActor
    func loadChapters() async {
        do {
            print("fetching chapters")
            manga.chapters = try await getChapters(manga: manga)
        } catch {
            print("failed to get chapters")
        }
    }
    
    @MainActor
    func loadVolumes() async {
        do {
            print("fetching volumes")
            manga.volumes = try await getVolumes(manga: manga)
        } catch {
            print("failed to get volumes")
        }
    }
}

struct ChapterRow: View {
    let chapter: Chapter
    let chapters: [Chapter]
    let readerMode: Bool

    var body: some View {
        NavigationLink {
            ReaderView(model: WebViewModel(chapter: chapter, chapters: chapters), readerMode: readerMode)
                .navigationBarTitleDisplayMode(.inline)
            
            
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(chapter.name)
                        .foregroundColor(.secondary)
                        .bold()
                }
                .padding()
                .padding([.leading], 10)
                Spacer()
                Image(systemName: "chevron.forward")
                  .font(Font.system(.caption).weight(.bold))
                  .foregroundColor(Color(UIColor.tertiaryLabel))
                  .padding([.trailing], 20)
            }
        }
    }
}

struct SortOrderStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        return HStack {
            Image(systemName: configuration.isOn ? "arrow.up" : "arrow.down")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
                .padding([.leading],3)
        }
    }
}

//struct MangaView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {MangaView(manga: .constant(Manga(name: "Cat Dog Something", link: "/cat-vs-dog-58824", image: "https://img.mreadercdn.com/_r/300x400/100/ad/9d/ad9dd75599622058318da9070001196d/ad9dd75599622058318da9070001196d.jpg")), saved: true) {print("save")} deleteAction: {print("delete")}
//        }
//    }
//}
