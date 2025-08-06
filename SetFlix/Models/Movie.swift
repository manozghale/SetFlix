//
//  Movie.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

struct Movie: Codable, Identifiable, Equatable {
  let id: Int
  let title: String
  let releaseDate: String
  let posterPath: String?

  // Custom coding keys to handle snake_case from API
  enum CodingKeys: String, CodingKey {
    case id
    case title
    case releaseDate = "release_date"
    case posterPath = "poster_path"
  }

  // Computed property for poster URL
  var posterURL: String? {
    guard let posterPath = posterPath else { return nil }
    return "https://image.tmdb.org/t/p/w500\(posterPath)"
  }

  // Computed property for formatted release date
  var formattedReleaseDate: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    guard let date = dateFormatter.date(from: releaseDate) else {
      return releaseDate
    }

    dateFormatter.dateStyle = .medium
    return dateFormatter.string(from: date)
  }
}

// MARK: - Search Response
struct MovieSearchResponse: Codable {
  let page: Int
  let results: [Movie]
  let totalPages: Int
  let totalResults: Int

  enum CodingKeys: String, CodingKey {
    case page
    case results
    case totalPages = "total_pages"
    case totalResults = "total_results"
  }
}
