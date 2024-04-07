//
//  Manga.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/17/22.
//

import Foundation
import SwiftSoup
import WebKit

let baseurlString = "https://mangareader.to"
let baseurl = URL(string: baseurlString)!

final class Manga: ObservableObject, Codable, Hashable {
    static func == (lhs: Manga, rhs: Manga) -> Bool {
        lhs.link == rhs.link
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(link)
    }

    let name: String
    let link: String
    let image: String
    
    @Published var chapters: [Chapter] = []
    @Published var volumes: [Chapter] = []
    
    @Published var readingByChapter: Bool = true
    @Published var lastToFirst: Bool = false
    @Published var langPref: Lang = Lang.en
        
    init(name: String, link: String, image: String) {
        self.name = name
        self.link = link
        self.image = image
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case link
        case image
        
        case chapters
        case volumes
        
        case readingByChapter
        case langPref
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        link = try values.decode(String.self, forKey: .link)
        image = try values.decode(String.self, forKey: .image)
        
        chapters = try values.decode([Chapter].self, forKey: .chapters)
        volumes = try values.decode([Chapter].self, forKey: .volumes)
        
        readingByChapter = try values.decode(Bool.self, forKey: .readingByChapter)
        langPref = try values.decode(Lang.self, forKey: .langPref)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(link, forKey: .link)
        try container.encode(image, forKey: .image)
        
        try container.encode(chapters, forKey: .chapters)
        try container.encode(volumes, forKey: .volumes)
    
        try container.encode(readingByChapter, forKey: .readingByChapter)
        try container.encode(langPref, forKey: .langPref)
    }
}

struct Chapter: Codable, Hashable {
    let name: String
    let link: String
    let lang: Lang
    
    var have_read: Bool = false
}

enum Lang: String, CaseIterable, Codable {
    case en
    case fr
    case ja
    case ko
    case zh
}

struct mangaReaderImgRequest: Codable {
    let status: Bool
    let html: String
}

enum PageOption: String, CaseIterable, Codable {
    case a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,other
    case numeric = "0-9"
}

enum getMangaError : Error {
    case invalidURL
}

func getMangaFromUrl(url: URL) async throws -> Manga {
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8)!
    let doc: Document = try SwiftSoup.parse(html)
    
    let name = try doc.select("h2.manga-name").text()
    let image = try doc.select("img.manga-poster-img").attr("src")
    if name == "" || image == "" {
        throw getMangaError.invalidURL
    }

    return Manga(name: name, link: url.absoluteString, image: image)
}

func getMangasByPage(option: PageOption?, page: Int) async throws -> [Manga] {
    let url = URL(string: option == nil ? "/az-list?page=\(page)" : "/az-list/\(option!.rawValue)?page=\(page)", relativeTo: baseurl)!
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8)!
    let doc: Document = try SwiftSoup.parse(html)
    
    return try await getMangasOnPage(doc: doc)
}

//&page=2 add page functionality
func getMangasBySearch(query: String) async throws -> [Manga] {
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    let url = URL(string: "/search?keyword=\(encodedQuery ?? "")", relativeTo: baseurl)!
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8)!
    let doc: Document = try SwiftSoup.parse(html)
    
    return try await getMangasOnPage(doc: doc)
}

func getMangasOnPage(doc: Document) async throws -> [Manga] {
    let mangas = try doc.select("#main-content div.item-spc")
    
    var mangaList = [Manga]()
    
    for manga in mangas {
        let titleInfo = try manga.select("div.manga-detail h3 a")
        
        let name = try titleInfo.attr("title")
        let link = try titleInfo.attr("href")
        let image = try manga.select("a img").attr("src")
        
        mangaList.append(Manga(name: name, link: link, image: image))
    }
    return mangaList
}

func getChapters(manga: Manga) async throws -> [Chapter] {
    let url = URL(string: manga.link, relativeTo: baseurl)!
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8)!
    let doc: Document = try SwiftSoup.parse(html)
    
    let chapters = try doc.select("div.chapters-list-ul ul li a")
    
    return try chapters.enumerated().compactMap { index, chapter in
        guard let name = try? chapter.attr("title"),
              let link = try? chapter.attr("href"),
              let langSection = try chapters[index].parent()!.parent()?.attr("id"),
              let range = langSection.range(of: "(en)|(ja)|(ko)|(zh)|(fr)", options: .regularExpression),
              let lang = Lang(rawValue: String(langSection[range]))
        else {
            return nil
        }
        return Chapter(name: name, link: link, lang: lang)
    }
}

func getVolumes(manga: Manga) async throws -> [Chapter] {
    let url = URL(string: manga.link, relativeTo: baseurl)!
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8)!
    let doc: Document = try SwiftSoup.parse(html)
    
    let volumes = try doc.select("div.volume-list-ul .item .manga-poster")
    
    return try volumes.enumerated().map { index, volume in
        let name = try volume.select("span").text()
        let link = try volume.select("a.link-mask").attr("href")
        
        let langSection = try volumes[index].parent()!.parent()!.attr("id")
        let range = langSection.range(of: "(en)|(ja)|(ko)|(zh)|(fr)", options: .regularExpression)!
        let lang = Lang(rawValue: String(langSection[range]))!

        return Chapter(name: name, link: link, lang: lang)
    }
}


