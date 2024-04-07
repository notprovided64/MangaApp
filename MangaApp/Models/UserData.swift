//
//  MangaContainer.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/17/22.
//

import Foundation

struct UserSettings: Codable, Hashable {
    var readingByChapter: Bool = true
}

class UserData: ObservableObject{
    @Published var items: [Manga] = []
    var userSettings = UserSettings()

    private static func mangaFileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil,
                                       create: false)
            .appendingPathComponent("manga.data")
    }
    
    static func load() async throws -> [Manga] {
        try await withCheckedThrowingContinuation { continuation in
            load { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let series):
                    continuation.resume(returning: series)
                }
            }
        }
    }
    
    static func load(completion: @escaping (Result<[Manga], Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try mangaFileURL()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else{
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                let series = try JSONDecoder().decode([Manga].self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(Array(Set(series)) ))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    @discardableResult
    static func save(series: [Manga]) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            save(series: series) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let saved):
                    continuation.resume(returning: saved)
                }
            }
        }
    }
    
    static func save(series: [Manga], completion: @escaping (Result<Int, Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(series)
                let outfile = try mangaFileURL()
                try data.write(to: outfile)
                DispatchQueue.main.async {
                    completion(.success(series.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
